fs = require "fs"
{Emitter} = require "event-kit"
Point = require "./point"
Range = require "./range"
MarkerStore = require "./marker-store"
NullLayer = require "./null-layer"
BufferLayer = require "./buffer-layer"
TransformLayer = require "./transform-layer"
LinesTransform = require "./lines-transform"
History = require "./history"

TransactionAborted = Symbol("transaction aborted")

LineEnding = /[\r\n]*$/

module.exports =
class TextDocument
  constructor: (options) ->
    @transactCallDepth = 0
    @history = new History
    @markerStore = new MarkerStore(this)
    @emitter = new Emitter
    @refcount = 1
    @destroyed = false
    @encoding = 'utf8'
    @bufferLayer = new BufferLayer(new NullLayer)
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

  onWillChange: (callback) ->
    @emitter.on("will-change", callback)

  onDidDestroy: (callback) ->
    @emitter.on("did-destroy", callback)

  onWillThrowWatchError: (callback) ->
    @emitter.on("will-throw-watch-error", callback)

  onDidSave: (callback) ->
    @emitter.on("did-save", callback)

  onDidChangePath: (callback) ->
    @emitter.on("did-change-path", callback)

  preemptDidChange: (callback) ->
    @emitter.preempt("did-change", callback)

  onDidUpdateMarkers: (callback) ->
    @emitter.on("did-update-markers", callback)

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

  onDidCreateMarker: (callback) ->
    @emitter.on("did-create-marker", callback)

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
        resolve(this)

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
    unless @transactCallDepth > 0
      return @transact => @setTextInRange(oldRange, newText)
    oldRange = Range.fromObject(oldRange)
    oldRange.start = @clipPosition(oldRange.start)
    oldRange.end = @clipPosition(oldRange.end)
    oldText = @getTextInRange(oldRange)
    @applyChange({oldRange, oldText, newText})

  append: (text) ->
    @insert(@getEndPosition(), text)

  insert: (position, text) ->
    @setTextInRange(Range(position, position), text)

  delete: (range) ->
    @setTextInRange(range, "")

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

  getRange: ->
    Range(Point.zero(), @getEndPosition())

  rangeForRow: (row, includeNewline) ->
    if includeNewline
      Range(Point(row, 0), @clipPosition(Point(row + 1, 0)))
    else
      Range(Point(row, 0), @clipPosition(Point(row, Infinity)))

  getLineCount: ->
    @getEndPosition().row + 1

  getLastRow: ->
    @getEndPosition().row

  getEndPosition: ->
    @linesLayer.getExtent()

  clipPosition: (position) ->
    position = Point.fromObject(position)
    @linesLayer.clipPosition(position)

  positionForCharacterIndex: (index) ->
    @linesLayer.fromInputPosition(new Point(0, index))

  characterIndexForPosition: (position) ->
    @linesLayer.toInputPosition(Point.fromObject(position)).column

  ###
  Section: History
  ###

  undo: ->
    if poppedEntries = @history.popUndoStack(@markerStore.createSnapshot())
      @applyChange(change, true) for change in poppedEntries.changes
      @markerStore.restoreFromSnapshot(poppedEntries.metadata)
      @emitter.emit("did-update-markers")

  redo: ->
    if poppedEntries = @history.popRedoStack(@markerStore.createSnapshot())
      @applyChange(change, true) for change in poppedEntries.changes
      @markerStore.restoreFromSnapshot(poppedEntries.metadata)
      @emitter.emit("did-update-markers")

  transact: (groupingInterval, fn) ->
    if typeof groupingInterval is 'function'
      fn = groupingInterval
      groupingInterval = 0

    checkpoint = @history.createCheckpoint(@markerStore.createSnapshot())

    try
      @transactCallDepth++
      result = fn()
    catch exception
      @revertToCheckpoint(checkpoint)
      throw exception unless exception is TransactionAborted
      return
    finally
      @transactCallDepth--

    @history.groupChangesSinceCheckpoint(checkpoint)
    @history.applyCheckpointGroupingInterval(checkpoint, groupingInterval)

    @markerStore.emitChangeEvents()
    @emitter.emit("did-update-markers")
    result

  abortTransaction: ->
    throw TransactionAborted

  createCheckpoint: ->
    @history.createCheckpoint()

  groupChangesSinceCheckpoint: (checkpoint) ->
    @history.groupChangesSinceCheckpoint(checkpoint)

  revertToCheckpoint: (checkpoint) ->
    if changesToUndo = @history.truncateUndoStack(checkpoint)
      @applyChange(change, true) for change in changesToUndo
      true
    else
      false

  ###
  Section: Private
  ###

  markerCreated: (marker) ->
    @emitter.emit("did-create-marker", marker)

  applyChange: (change, skipUndo) ->
    @emitter.emit("will-change", change)
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
