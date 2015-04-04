Layer = require "./layer"
Point = require "./point"
TransformBuffer = require './transform-buffer'

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

  constructor: (@layer, @sourceIterator) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformBuffer = new TransformBuffer(@layer.transformer, @sourceIterator)

  next: ->
    if next = @transformBuffer.next()
      {content, @position, @sourcePosition, @clipping} = next
      {value: content, done: false}
    else
      {value: undefined, done: true}

  seek: (position, clip=CLIP_BACKWARD) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformBuffer.reset(@position, @sourcePosition)
    position = Point.fromObject(position).sanitizeNegatives()
    return if position.isZero()

    done = overshot = false
    until done or overshot
      lastPosition = @position
      lastSourcePosition = @sourcePosition
      {done} = @next()
      switch @position.compare(position)
        when 0 then done = true
        when 1 then overshot = true

    if overshot
      if @clipping?
        if clip is CLIP_BACKWARD
          @position = lastPosition
          @sourcePosition = lastSourcePosition
      else
        @position = position
        overshoot = position.traversalFrom(lastPosition)
        sourcePositionWithOvershoot = lastSourcePosition.traverse(overshoot)
        if sourcePositionWithOvershoot.compare(@sourcePosition) >= 0
          if clip is CLIP_BACKWARD
            @sourcePosition = @sourcePosition.traverse(Point(0, -1))
        else
          @sourcePosition = sourcePositionWithOvershoot

    @transformBuffer.reset(@position, @sourcePosition)

  seekToSourcePosition: (sourcePosition, clip = CLIP_BACKWARD) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformBuffer.reset(@position, @sourcePosition)
    sourcePosition = Point.fromObject(sourcePosition).sanitizeNegatives()
    return if sourcePosition.isZero()

    done = overshot = false
    until done or overshot
      lastPosition = @position
      lastSourcePosition = @sourcePosition
      {done} = @next()
      switch @sourcePosition.compare(sourcePosition)
        when 0 then done = true
        when 1 then overshot = true

    if overshot
      if @clipping?
        if clip is CLIP_BACKWARD
          @position = lastPosition
          @sourcePosition = lastSourcePosition
      else
        @sourcePosition = sourcePosition
        overshoot = sourcePosition.traversalFrom(lastSourcePosition)
        positionWithOvershoot = lastPosition.traverse(overshoot)
        if positionWithOvershoot.compare(@position) >= 0
          if clip is CLIP_BACKWARD
            @position = @position.traverse(Point(0, -1))
        else
          @position = positionWithOvershoot

    @transformBuffer.reset(@position, @sourcePosition)

  splice: (extent, content) ->
    startPosition = @getPosition()
    sourceStartPosition = @getSourcePosition()
    @seek(@getPosition().traverse(extent))
    sourceExtent = @getSourcePosition().traversalFrom(sourceStartPosition)
    @seekToSourcePosition(sourceStartPosition)
    @sourceIterator.splice(sourceExtent, content)
    @seekToSourcePosition(@sourceIterator.getPosition())

  getPosition: ->
    @position.copy()

  getSourcePosition: ->
    @sourcePosition.copy()
