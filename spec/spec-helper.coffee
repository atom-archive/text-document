require 'coffee-cache'

exports.expectMappings = (layer, mappings) ->
  for [currentLayerPosition, upperLayerPosition] in mappings
    expect(
      layer.positionInTopmostLayer(currentLayerPosition)
    ).toEqual(upperLayerPosition)

    expect(
      layer.positionFromTopmostLayer(upperLayerPosition)
    ).toEqual(currentLayerPosition)
