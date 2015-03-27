fs = require "fs"
{Emitter} = require "event-kit"
Point = require "./point"
Range = require "./range"
Marker = require "./marker"
BufferLayer = require "./buffer-layer"
StringLayer = require "./string-layer"
LinesTransform = require "./lines-transform"
TransformLayer = require "./transform-layer"

LineEnding = /[\r\n]*$/

module.exports =
class TextDocument
  linesLayer: null

  ###
  Section: Construction
  ###

  constructor: (options) ->
    @nextMarkerId = 0
    @markers = []
    @emitter = new Emitter
    @refcount = 1
    @destroyed = false
    @encoding = 'utf8'
    @bufferLayer = new BufferLayer(new StringLayer(""))
    if typeof options is 'string'
      @setText(options)
    else if options?.filePath?
      @setPath(options.filePath)
      @load() if options.load

  ###
  Section: Lifecycle
  ###

  destroy: ->
    @destroyed = true
    @emitter.emit "did-destroy"

  retain: ->
    @refcount++

  release: ->
    @refcount--
    @destroy() if @refcount is 0

  isAlive: ->
    not @destroyed

  isDestroyed: ->
    @destroyed

  ###
  Section: Event Subscription
  ###

  onDidChange: (callback) ->
    @emitter.on("did-change", callback)

  onDidDestroy: (callback) ->
    @emitter.on("did-destroy", callback)

  onWillThrowWatchError: (callback) ->
    @emitter.on("will-throw-watch-error", callback)

  onDidSave: (callback) ->
    @emitter.on("did-save", callback)

  onDidChangePath: (callback) ->
    @emitter.on("did-change-path", callback)

  preemptDidChange: (callback) ->
    @emitter.preempt("did-change-path", callback)

  onDidUpdateMarkers: (callback) ->
    @emitter.on("did-update-markers", callback)

  onDidCreateMarker: (callback) ->
    @emitter.on("did-create-marker", callback)

  onDidChangeEncoding: (callback) ->
    @emitter.on("did-change-encoding", callback)

  onDidStopChanging: (callback) ->
    @emitter.on("did-stop-changing", callback)

  onDidConflict: (callback) ->
    @emitter.on("did-conflict", callback)

  onDidChangeModified: (callback) ->
    @emitter.on("did-change-modified", callback)

  onWillReload: (callback) ->
    @emitter.on("will-reload", callback)

  onDidReload: (callback) ->
    @emitter.on("did-reload", callback)

  onWillSave: (callback) ->
    @emitter.on("will-save", callback)

  ###
  Section: File Details
  ###

  getPath: -> @path

  getUri: -> @path

  setPath: (@path) ->
    @loaded = false

  load: ->
    new Promise (resolve) =>
      fs.readFile @path, @encoding, (err, contents) =>
        @loaded = true
        @setText(contents) if contents
        @emitter.emit("did-load")
        resolve()

  isModified: ->
    false

  setEncoding: (@encoding) ->

  getEncoding: -> @encoding

  ###
  Section: Reading Text
  ###

  getText: ->
    @getLinesLayer().slice()

  getTextInRange: (range) ->
    range = Range.fromObject(range)
    @getLinesLayer().slice(range.start, range.end)

  setText: (text) ->
    @bufferLayer.splice(Point.zero(), @bufferLayer.getExtent(), text)

  setTextInRange: (oldRange, newText) ->
    oldRange = Range.fromObject(oldRange)
    linesLayer = @getLinesLayer()
    oldText = @getTextInRange(oldRange)
    start = linesLayer.toSourcePosition(oldRange.start)
    end = linesLayer.toSourcePosition(oldRange.end)
    @bufferLayer.splice(start, end.traversalFrom(start), newText)
    newRange = new Range(oldRange.start, linesLayer.fromSourcePosition(start.traverse(Point(0, newText.length))))
    @emitter.emit("did-change", {oldText, newText, oldRange, newRange})
    newRange

  lineForRow: (row) ->
    @getLinesLayer()
      .slice(Point(row, 0), Point(row + 1, 0))
      .replace(LineEnding, "")

  lineEndingForRow: (row) ->
    @getLinesLayer()
      .slice(Point(row, 0), Point(row + 1, 0))
      .match(LineEnding, "")[0]

  isEmpty: ->
    @bufferLayer.getExtent().isZero()

  previousNonBlankRow: -> 0

  nextNonBlankRow: -> 0

  isRowBlank: -> false

  ###
  Section: Markers
  ###

  getMarker: (id) ->
    return marker for marker in @markers when marker.id is id

  getMarkers: ->
    @markers

  findMarkers: (params) ->
    @markers.filter (marker) -> marker.matchesParams(params)

  markPosition: (position, options) ->
    marker = new Marker(@nextMarkerId++, new Range(Point.fromObject(position), Point.fromObject(position)), options)
    @markers.push(marker)
    @emitter.emit("did-create-marker", marker)
    marker

  ###
  Section: Buffer Range Details
  ###

  getLineCount: ->
    @getLinesLayer().getExtent().row + 1

  getLastRow: ->
    @getLineCount() - 1

  clipPosition: (position) ->
    position = Point.fromObject(position)
    @getLinesLayer().clipPosition(position)

  positionForCharacterIndex: (index) ->
    @getLinesLayer().fromSourcePosition(new Point(0, index))

  characterIndexForPosition: (position) ->
    @getLinesLayer().toSourcePosition(Point.fromObject(position)).column

  ###
  Section: History
  ###

  transact: (groupingInterval, fn) ->
    if typeof groupingInterval is 'function'
      fn = groupingInterval
      groupingInterval = 0
    fn()

  groupChangesSinceCheckpoint: ->

  ###
  Section: Private
  ###

  getLinesLayer: ->
    @linesLayer ?= new TransformLayer(@bufferLayer, new LinesTransform)
