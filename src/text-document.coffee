Point = require "./point"
BufferLayer = require "./buffer-layer"
StringLayer = require "./string-layer"
LinesTransform = require "./lines-transform"
TransformLayer = require "./transform-layer"

module.exports =
class TextDocument
  linesLayer: null

  constructor: (text) ->
    @bufferLayer = new BufferLayer(new StringLayer(""))
    @setText(text) if text?

  getText: ->
    @getLinesLayer().slice()

  setText: (text) ->
    @bufferLayer.splice(Point.zero(), @bufferLayer.getExtent(), text)

  getLineCount: ->
    @getLinesLayer().getExtent().row + 1

  lineForRow: (row) ->
    @getLinesLayer()
      .slice(Point(row, 0), Point(row + 1, 0))
      .replace(/\s*$/, "")

  lineEndingForRow: (row) ->
    @getLinesLayer()
      .slice(Point(row, 0), Point(row + 1, 0))
      .match(/\s*$/, "")[0]

  clipPosition: (position) ->
    position = Point.fromObject(position)
    @getLinesLayer().clipPosition(position)

  positionForCharacterIndex: (index) ->
    @getLinesLayer().fromSourcePosition(new Point(0, index))

  characterIndexForPosition: (position) ->
    @getLinesLayer().toSourcePosition(Point.fromObject(position)).column

  getLinesLayer: ->
    @linesLayer ?= new TransformLayer(@bufferLayer, new LinesTransform)
