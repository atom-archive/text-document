Point = require "./point"
BufferLayer = require "./buffer-layer"
StringLayer = require "./string-layer"
LinesTransform = require "./lines-transform"
TransformLayer = require "./transform-layer"

module.exports =
class TextDocument
  linesLayer: null

  constructor: ->
    @bufferLayer = new BufferLayer(new StringLayer(""))

  setText: (text) ->
    @bufferLayer.splice(Point.zero(), @bufferLayer.getExtent(), text)

  getLinesLayer: ->
    @linesLayer ?= new TransformLayer(@bufferLayer, new LinesTransform)

  clipPosition: (position) ->
    position = Point.fromObject(position)
    @getLinesLayer().clipPosition(position)

  positionForCharacterIndex: (index) ->
    @getLinesLayer().fromSourcePosition(
      new Point(0, index)
    )

  characterIndexForPosition: (position) ->
    position = Point.fromObject(position)

    @getLinesLayer().toSourcePosition(position).column
