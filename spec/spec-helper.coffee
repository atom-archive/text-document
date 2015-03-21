require 'coffee-cache'

exports.expectMappings = (targetLayer, mappings) ->
  for [targetLayerPosition, sourceLayerPosition] in mappings
    expect(
      targetLayer.sourcePositionForPosition(targetLayerPosition)
    ).toEqual(sourceLayerPosition)

    expect(
      targetLayer.positionForSourcePosition(sourceLayerPosition)
    ).toEqual(targetLayerPosition)
