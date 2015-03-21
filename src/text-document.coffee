Point = require "./point"
BufferLayer = require "./buffer-layer"
StringLayer = require "./string-layer"
PairedCharactersTransform = require "./paired-characters-transform"
LinesTransform = require "./lines-transform"
HardTabsTransform = require "./hard-tabs-transform"
SoftWrapsTransform = require "./soft-wraps-transform"
TransformLayer = require "./transform-layer"

module.exports =
class TextDocument
  linesLayer: null

  constructor: (options) ->
    @bufferLayer  = new BufferLayer(new StringLayer(""))
    @displayLayer = @buildDisplayLayer(options)

  setText: (text) ->
    @bufferLayer.splice(Point.zero(), @bufferLayer.getExtent(), text)

  getLinesLayer: ->
    @linesLayer ?= new TransformLayer(@bufferLayer, new LinesTransform)

  buildDisplayLayer: ({softWrapColumn, tabLength}) ->
    transforms = [
      new HardTabsTransform(tabLength),
      new SoftWrapsTransform(softWrapColumn)
    ]

    transforms.reduce(
      (previousLayer, transform) -> new TransformLayer(previousLayer, transform)
      @getLinesLayer()
    )

  characterIndexForPosition: (position) ->
    @sourcePositionForPosition(
      position, @displayLayer, @bufferLayer
    ).column

  positionForCharacterIndex: (charIndex) ->
    position = new Point(0, charIndex)

    @positionForSourcePosition(position, @displayLayer, @bufferLayer)

  sourcePositionForPosition: (position, currentLayer, sourceLayer) ->
    return position if currentLayer is sourceLayer

    @sourcePositionForPosition(
      currentLayer.sourcePositionForPosition(position),
      currentLayer.sourceLayer,
      sourceLayer
    )

  positionForSourcePosition: (position, currentLayer, sourceLayer) ->
    return position if currentLayer is sourceLayer

    position = @positionForSourcePosition(
      position,
      currentLayer.sourceLayer,
      sourceLayer
    )

    currentLayer.positionForSourcePosition(position)
