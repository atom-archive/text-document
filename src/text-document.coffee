fs = require "fs"
{Emitter} = require "event-kit"
Point = require "./point"
Range = require "./range"
MarkerStore = require "./marker-store"
BufferLayer = require "./buffer-layer"
StringLayer = require "./string-layer"
LinesTransform = require "./lines-transform"
TransformLayer = require "./transform-layer"
History = require "./history"
TransactionAbortedException = require './transaction-aborted-exception'

LineEnding = /[\r\n]*$/

module.exports =
class TextDocument
  constructor: (options) ->
    @history = new History
    @markerStore = new MarkerStore
    @emitter = new Emitter
    @refcount = 1
    @destroyed = false
    @encoding = 'utf8'
    @bufferLayer = new BufferLayer(new StringLayer(""))
    @linesLayer = new TransformLayer(@bufferLayer, new LinesTransform)
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
    @markerStore.onDidCreateMarker(callback)

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
    @linesLayer.slice()

  getTextInRange: (range) ->
    range = Range.fromObject(range)
    @linesLayer.slice(range.start, range.end)

  setText: (text) ->
    @bufferLayer.splice(Point.zero(), @bufferLayer.getExtent(), text)

  setTextInRange: (oldRange, newText) ->
    oldRange = Range.fromObject(oldRange)
    oldText = @getTextInRange(oldRange)
    @applyChange({oldRange, oldText, newText})

  lineForRow: (row) ->
    @linesLayer
      .slice(Point(row, 0), Point(row + 1, 0))
      .replace(LineEnding, "")

  lineEndingForRow: (row) ->
    @linesLayer
      .slice(Point(row, 0), Point(row + 1, 0))
      .match(LineEnding)[0]

  isEmpty: ->
    @bufferLayer.getExtent().isZero()

  previousNonBlankRow: -> 0

  nextNonBlankRow: -> 0

  isRowBlank: -> false

  ###
  Section: Markers
  ###

  getMarker: (id) -> @markerStore.getMarker(id)
  getMarkers: -> @markerStore.getMarkers()
  findMarkers: (params) -> @markerStore.findMarkers(params)
  markRange: (range, options) -> @markerStore.markRange(range, options)
  markPosition: (position, options) -> @markerStore.markPosition(position, options)

  ###
  Section: Buffer Range Details
  ###

  getLineCount: ->
    @linesLayer.getExtent().row + 1

  getLastRow: ->
    @getLineCount() - 1

  clipPosition: (position) ->
    position = Point.fromObject(position)
    @linesLayer.clipPosition(position)

  positionForCharacterIndex: (index) ->
    @linesLayer.fromSourcePosition(new Point(0, index))

  characterIndexForPosition: (position) ->
    @linesLayer.toSourcePosition(Point.fromObject(position)).column

  ###
  Section: History
  ###

  undo: ->
    if transaction = @history.popUndoStack()
      @applyChange(change, true) for change in transaction.changes

  redo: ->
    if transaction = @history.popRedoStack()
      @applyChange(change, true) for change in transaction.changes

  transact: (groupingInterval, fn) ->
    if typeof groupingInterval is 'function'
      fn = groupingInterval
      groupingInterval = 0

    exceptionToRethrow = null
    try
      try
        @history.transact(groupingInterval, fn)
      catch innerException
        if innerException instanceof TransactionAbortedException
          throw innerException
        else
          exceptionToRethrow = innerException
          @abortTransaction()
    catch abortException
      @applyChange(change, true) for change in abortException.transaction.changes
      throw exceptionToRethrow if exceptionToRethrow?

  abortTransaction: -> @history.abortTransaction()

  groupChangesSinceCheckpoint: ->

  ###
  Section: Private
  ###

  applyChange: (change, skipUndo) ->
    {oldRange, newText} = change
    start = oldRange.start
    oldExtent = oldRange.getExtent()

    newExtent = @linesLayer.splice(oldRange.start, oldRange.getExtent(), newText)
    @markerStore.splice(oldRange.start, oldExtent, newExtent)

    change.newRange ?= Range(start, start.traverse(newExtent))
    Object.freeze(change)

    @history.pushChange(change) unless skipUndo
    @emitter.emit("did-change", change)

    change.newRange
