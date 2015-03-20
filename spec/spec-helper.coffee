require 'coffee-cache'

exports.expectMappings = (currentLayer, upperLayer, mappings) ->
  for [currentLayerPosition, upperLayerPosition] in mappings
    expect(
      currentLayer.toPositionInLayer(currentLayerPosition, upperLayer)
    ).toEqual(upperLayerPosition)

    expect(
      currentLayer.fromPositionInLayer(upperLayerPosition, upperLayer)
    ).toEqual(currentLayerPosition)
