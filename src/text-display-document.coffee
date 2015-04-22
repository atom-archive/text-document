Point = require "./point"
PairedCharactersTransform = require "./paired-characters-transform"
HardTabsTransform = require "./hard-tabs-transform"
SoftWrapsTransform = require "./soft-wraps-transform"
TransformLayer = require "./transform-layer"
{clip} = TransformLayer

module.exports =
class TextDisplayDocument
  constructor: (@textDocument, {tabLength, softWrapColumn}={}) ->
    transforms = [
      new HardTabsTransform(tabLength)
      new SoftWrapsTransform(softWrapColumn)
      new PairedCharactersTransform()
    ]

    @layersByIndex = []
    inputLayer = @textDocument.linesLayer
    for transform in transforms
      layer = new TransformLayer(inputLayer, transform)
      @layersByIndex.push(layer)
      inputLayer = layer

  tokenizedLinesForScreenRows: (start, end) ->
    topLayer = @layersByIndex[@layersByIndex.length - 1]
    for lineText in topLayer.getLines()
      {text: lineText}

  screenPositionForBufferPosition: (position) ->
    position = @textDocument.clipPosition(position)
    for layer in @layersByIndex
      position = layer.fromInputPosition(position, clip.backward)
    position

  bufferPositionForScreenPosition: (position) ->
    for layer in @layersByIndex by -1
      position = layer.toInputPosition(position, clip.backward)
    @textDocument.clipPosition(position)
