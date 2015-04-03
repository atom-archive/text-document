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
    sourceLayer = @textDocument.linesLayer
    for transform in transforms
      layer = new TransformLayer(sourceLayer, transform)
      @layersByIndex.push(layer)
      sourceLayer = layer

  tokenizedLinesForScreenRows: (start, end) ->
    topLayer = @layersByIndex[@layersByIndex.length - 1]
    for lineText in topLayer.getLines()
      {text: lineText}

  screenPositionForBufferPosition: (position) ->
    position = @textDocument.clipPosition(position)
    for layer in @layersByIndex
      position = layer.fromSourcePosition(position, clip.backward)
    position

  bufferPositionForScreenPosition: (position) ->
    for layer in @layersByIndex by -1
      position = layer.toSourcePosition(position, clip.backward)
    @textDocument.clipPosition(position)
