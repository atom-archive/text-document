Layer = require "./layer"
Point = require "./point"
TransformIterator = require './transform-iterator'

CLIP_FORWARD = Symbol('clip forward')
CLIP_BACKWARD = Symbol('clip backward')

module.exports =
class TransformLayer extends Layer
  @clip:
    forward: CLIP_FORWARD
    backward: CLIP_BACKWARD

  pendingChangeOldExtent: null

  constructor: (@sourceLayer, @transformer) ->
    super
    @sourceLayer.onWillChange(@sourceLayerWillChange)
    @sourceLayer.onDidChange(@sourceLayerDidChange)

  buildIterator: ->
    new TransformLayerIterator(this, @sourceLayer.buildIterator())

  sourceLayerWillChange: ({position, oldExtent}) =>
    iterator = @buildIterator()
    iterator.seekToSourcePosition(position)
    startPosition = iterator.getPosition()
    iterator.seekToSourcePosition(position.traverse(oldExtent))
    @pendingChangeOldExtent = iterator.getPosition().traversalFrom(startPosition)

  sourceLayerDidChange: ({position, newExtent}) =>
    iterator = @buildIterator()
    iterator.seekToSourcePosition(position)
    startPosition = iterator.getPosition()
    iterator.seekToSourcePosition(position.traverse(newExtent))

    oldExtent = @pendingChangeOldExtent
    newExtent = iterator.getPosition().traversalFrom(startPosition)
    @pendingChangeOldExtent = null

    @emitter.emit "did-change", {position: startPosition, oldExtent, newExtent}

  clipPosition: (position, clip) ->
    iterator = @buildIterator()
    iterator.seek(position, clip)
    iterator.getPosition()

  toSourcePosition: (position, clip) ->
    iterator = @buildIterator()
    iterator.seek(position, clip)
    iterator.getSourcePosition()

  fromSourcePosition: (sourcePosition, clip) ->
    iterator = @buildIterator()
    iterator.seekToSourcePosition(sourcePosition, clip)
    iterator.getPosition()

class TransformLayerIterator
  clipping: undefined

  constructor: (@layer, sourceIterator) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformIterator = new TransformIterator(@layer.transformer, sourceIterator)

  next: ->
    unless (next = @transformIterator.next()).done
      @position = @transformIterator.getPosition()
      @sourcePosition = @transformIterator.getSourcePosition()
      @clipping = @transformIterator.getClippingStatus()
    next

  seek: (position, clip=CLIP_BACKWARD) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformIterator.reset(@position, @sourcePosition)
    position = Point.fromObject(position).sanitizeNegatives()
    return if position.isZero()

    until @position.compare(position) >= 0
      lastPosition = @position
      lastSourcePosition = @sourcePosition
      {done} = @next()
      return if done

    if @clipping? and @position.compare(position) > 0
      switch clip
        when CLIP_FORWARD
          return
        when CLIP_BACKWARD
          @position = lastPosition
          @sourcePosition = lastSourcePosition
          return

    unless @position.compare(position) is 0
      @position = position
      overshoot = position.traversalFrom(lastPosition)
      sourcePositionWithOvershoot = lastSourcePosition.traverse(overshoot)
      if sourcePositionWithOvershoot.compare(@sourcePosition) >= 0
        if clip is CLIP_BACKWARD
          @sourcePosition = @sourcePosition.traverse(Point(0, -1))
      else
        @sourcePosition = sourcePositionWithOvershoot
    @transformIterator.reset(@position, @sourcePosition)

  seekToSourcePosition: (sourcePosition, clip = CLIP_BACKWARD) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformIterator.reset(@position, @sourcePosition)
    sourcePosition = Point.fromObject(sourcePosition).sanitizeNegatives()
    return if sourcePosition.isZero()

    until @sourcePosition.compare(sourcePosition) >= 0
      lastPosition = @position
      lastSourcePosition = @sourcePosition
      {done} = @next()
      return if done

    if @clipping? and @sourcePosition.compare(sourcePosition) > 0
      switch clip
        when CLIP_FORWARD
          return
        when CLIP_BACKWARD
          @position = lastPosition
          @sourcePosition = lastSourcePosition
          return

    unless @sourcePosition.compare(sourcePosition) is 0
      @sourcePosition = sourcePosition
      overshoot = sourcePosition.traversalFrom(lastSourcePosition)
      positionWithOvershoot = lastPosition.traverse(overshoot)
      if positionWithOvershoot.compare(@position) >= 0
        if clip is CLIP_BACKWARD
          @position = @position.traverse(Point(0, -1))
      else
        @position = positionWithOvershoot
    @transformIterator.reset(@position, @sourcePosition)

  getPosition: ->
    @position.copy()

  getSourcePosition: ->
    @sourcePosition.copy()
