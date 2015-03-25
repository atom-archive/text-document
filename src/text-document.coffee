fs = require "fs"
{Emitter} = require "event-kit"
Point = require "./point"
BufferLayer = require "./buffer-layer"
StringLayer = require "./string-layer"
LinesTransform = require "./lines-transform"
TransformLayer = require "./transform-layer"

LineEnding = /[\r\n]*$/

module.exports =
class TextDocument
  linesLayer: null

  constructor: (options) ->
    @emitter = new Emitter
    @encoding = 'utf8'
    @bufferLayer = new BufferLayer(new StringLayer(""))
    if typeof options is 'string'
      @setText(options)
    else if options?.filePath?
      @setPath(options.filePath, options.load)
      @load() if options.load

  destroy: ->

  setPath: (@path) ->
    @loaded = false

  load: ->
    fs.readFile @path, @encoding, (err, contents) =>
      @loaded = true
      @setText(contents) if contents
      @emitter.emit("did-load")

  onDidLoad: (fn) ->
    @emitter.on("did-load", fn)

  getText: ->
    @getLinesLayer().slice()

  setText: (text) ->
    @bufferLayer.splice(Point.zero(), @bufferLayer.getExtent(), text)

  isModified: ->
    false

  getLineCount: ->
    @getLinesLayer().getExtent().row + 1

  lineForRow: (row) ->
    @getLinesLayer()
      .slice(Point(row, 0), Point(row + 1, 0))
      .replace(LineEnding, "")

  lineEndingForRow: (row) ->
    @getLinesLayer()
      .slice(Point(row, 0), Point(row + 1, 0))
      .match(LineEnding, "")[0]

  clipPosition: (position) ->
    position = Point.fromObject(position)
    @getLinesLayer().clipPosition(position)

  positionForCharacterIndex: (index) ->
    @getLinesLayer().fromSourcePosition(new Point(0, index))

  characterIndexForPosition: (position) ->
    @getLinesLayer().toSourcePosition(Point.fromObject(position)).column

  getLinesLayer: ->
    @linesLayer ?= new TransformLayer(@bufferLayer, new LinesTransform)
