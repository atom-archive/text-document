require 'coffee-cache'

exports.expectMappings = (targetLayer, sourceLayer, mappings) ->
  for [targetLayerPosition, sourceLayerPosition] in mappings
    expect(
      targetLayer.sourcePositionForPosition(targetLayerPosition, sourceLayer)
    ).toEqual(sourceLayerPosition)

    expect(
      targetLayer.positionForSourcePosition(sourceLayerPosition, sourceLayer)
    ).toEqual(targetLayerPosition)
