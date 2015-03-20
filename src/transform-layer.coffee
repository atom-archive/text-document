Layer = require "./layer"
Point = require "./point"
TransformIterator = require "./transform-iterator"

module.exports =
class TransformLayer extends Layer
  pendingChangeOldExtent: null

  constructor: (@sourceLayer, @transform) ->
    super
    @sourceLayer.onWillChange(@sourceLayerWillChange)
    @sourceLayer.onDidChange(@sourceLayerDidChange)

  @::[Symbol.iterator] = ->
    new TransformIterator(this, @sourceLayer[Symbol.iterator]())

  sourceLayerWillChange: ({position, oldExtent}) =>
    iterator = @[Symbol.iterator]()
    iterator.seekToSourcePosition(position)
    startPosition = iterator.getPosition()
    iterator.seekToSourcePosition(position.traverse(oldExtent))
    @pendingChangeOldExtent = iterator.getPosition().traversalFrom(startPosition)

  sourceLayerDidChange: ({position, newExtent}) =>
    iterator = @[Symbol.iterator]()
    iterator.seekToSourcePosition(position)
    startPosition = iterator.getPosition()
    iterator.seekToSourcePosition(position.traverse(newExtent))

    oldExtent = @pendingChangeOldExtent
    newExtent = iterator.getPosition().traversalFrom(startPosition)
    @pendingChangeOldExtent = null

    @emitter.emit "did-change", {position: startPosition, oldExtent, newExtent}

  positionInTopmostLayer: (position) ->
    iterator = @[Symbol.iterator]()
    iterator.seek(position)

    @sourceLayer.positionInTopmostLayer(
      iterator.getSourcePosition()
    )

  positionFromTopmostLayer: (sourcePosition) ->
    sourcePosition = @sourceLayer.positionFromTopmostLayer(sourcePosition)

    iterator = @[Symbol.iterator]()
    iterator.seekToSourcePosition(sourcePosition)
    iterator.getPosition()
