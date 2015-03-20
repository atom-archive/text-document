require 'coffee-cache'

exports.expectMappings = (layer, mappings) ->
  for [currentLayerPosition, upperLayerPosition] in mappings
    expect(
      layer.positionInUpperLayer(currentLayerPosition)
    ).toEqual(upperLayerPosition)

    expect(
      layer.positionFromUpperLayer(upperLayerPosition)
    ).toEqual(currentLayerPosition)
