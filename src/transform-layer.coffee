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

  constructor: (@inputLayer, @transformer) ->
    super
    @inputLayer.onWillChange(@inputLayerWillChange)
    @inputLayer.onDidChange(@inputLayerDidChange)

  buildIterator: ->
    new TransformLayerIterator(this, @inputLayer.buildIterator())

  inputLayerWillChange: ({position, oldExtent}) =>
    iterator = @buildIterator()
    iterator.seekToInputPosition(position)
    startPosition = iterator.getPosition()
    iterator.seekToInputPosition(position.traverse(oldExtent))
    @pendingChangeOldExtent = iterator.getPosition().traversalFrom(startPosition)

  inputLayerDidChange: ({position, newExtent}) =>
    iterator = @buildIterator()
    iterator.seekToInputPosition(position)
    startPosition = iterator.getPosition()
    iterator.seekToInputPosition(position.traverse(newExtent))

    oldExtent = @pendingChangeOldExtent
    newExtent = iterator.getPosition().traversalFrom(startPosition)
    @pendingChangeOldExtent = null

    @emitter.emit "did-change", {position: startPosition, oldExtent, newExtent}

  clipPosition: (position, clip) ->
    iterator = @buildIterator()
    iterator.seek(position, clip)
    iterator.getPosition()

  toInputPosition: (position, clip) ->
    iterator = @buildIterator()
    iterator.seek(position, clip)
    iterator.getInputPosition()

  fromInputPosition: (inputPosition, clip) ->
    iterator = @buildIterator()
    iterator.seekToInputPosition(inputPosition, clip)
    iterator.getPosition()

class TransformLayerIterator
  clipping: undefined

  constructor: (@layer, @inputIterator) ->
    @position = Point.zero()
    @inputPosition = Point.zero()
    @transformBuffer = new TransformBuffer(@layer.transformer, @inputIterator)

  next: ->
    if next = @transformBuffer.next()
      {content, @position, @inputPosition, @clipping} = next
      {value: content, done: false}
    else
      {value: undefined, done: true}

  seek: (position, clip=CLIP_BACKWARD) ->
    @position = Point.zero()
    @inputPosition = Point.zero()
    @inputIterator.seek(@inputPosition)
    @transformBuffer.reset(@position, @inputPosition)
    position = Point.fromObject(position).sanitizeNegatives()
    return if position.isZero()

    done = overshot = false
    until done or overshot
      lastPosition = @position
      lastInputPosition = @inputPosition
      {done} = @next()
      switch @position.compare(position)
        when 0 then done = true
        when 1 then overshot = true

    if overshot
      if @clipping?
        if clip is CLIP_BACKWARD
          @position = lastPosition
          @inputPosition = lastInputPosition
      else
        @position = position
        overshoot = position.traversalFrom(lastPosition)
        inputPositionWithOvershoot = lastInputPosition.traverse(overshoot)
        if inputPositionWithOvershoot.compare(@inputPosition) >= 0
          if clip is CLIP_BACKWARD
            @inputPosition = @inputPosition.traverse(Point(0, -1))
        else
          @inputPosition = inputPositionWithOvershoot

    @inputIterator.seek(@inputPosition)
    @transformBuffer.reset(@position, @inputPosition)

  seekToInputPosition: (inputPosition, clip = CLIP_BACKWARD) ->
    @position = Point.zero()
    @inputPosition = Point.zero()
    @inputIterator.seek(@inputPosition)
    @transformBuffer.reset(@position, @inputPosition)
    inputPosition = Point.fromObject(inputPosition).sanitizeNegatives()
    return if inputPosition.isZero()

    done = overshot = false
    until done or overshot
      lastPosition = @position
      lastInputPosition = @inputPosition
      {done} = @next()
      switch @inputPosition.compare(inputPosition)
        when 0 then done = true
        when 1 then overshot = true

    if overshot
      if @clipping?
        if clip is CLIP_BACKWARD
          @position = lastPosition
          @inputPosition = lastInputPosition
      else
        @inputPosition = inputPosition
        overshoot = inputPosition.traversalFrom(lastInputPosition)
        positionWithOvershoot = lastPosition.traverse(overshoot)
        if positionWithOvershoot.compare(@position) >= 0
          if clip is CLIP_BACKWARD
            @position = @position.traverse(Point(0, -1))
        else
          @position = positionWithOvershoot

    @inputIterator.seek(@inputPosition)
    @transformBuffer.reset(@position, @inputPosition)

  splice: (extent, content) ->
    startPosition = @getPosition()
    inputStartPosition = @getInputPosition()
    @seek(@getPosition().traverse(extent))
    inputExtent = @getInputPosition().traversalFrom(inputStartPosition)
    @seekToInputPosition(inputStartPosition)
    @inputIterator.splice(inputExtent, content)
    @seekToInputPosition(@inputIterator.getPosition())

  getPosition: ->
    @position.copy()

  getInputPosition: ->
    @inputPosition.copy()
