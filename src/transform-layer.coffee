Layer = require "./layer"
Point = require "./point"
OperatorIterator = require './operator-iterator'

CLIP_FORWARD = Symbol('clip forward')
CLIP_BACKWARD = Symbol('clip backward')

module.exports =
class TransformLayer extends Layer
  clip:
    forward: CLIP_FORWARD
    backward: CLIP_BACKWARD
  pendingChangeOldExtent: null

  constructor: (@sourceLayer, @operator) ->
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
    @transformBuffer = new OperatorIterator(@layer.operator, sourceIterator)

  next: ->
    if next = @transformBuffer.next()
      {@position, @sourcePosition, content, @clipping} = next
      {value: content, done: false}
    else
      {value: undefined, done: true}

  seek: (position, clip=CLIP_BACKWARD) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformBuffer.reset(@position, @sourcePosition)
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
          @sourcePosition = lastSourcePosition
          return

    unless @position.compare(position) is 0
      overshoot = position.column - lastPosition.column
      lastSourcePosition.column += overshoot
      @position = position
      @sourcePosition = lastSourcePosition
    @transformBuffer.reset(@position, @sourcePosition)

  seekToSourcePosition: (position) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformBuffer.reset(@position, @sourcePosition)
    return if position.isZero()

    until @sourcePosition.compare(position) >= 0
      lastPosition = @position
      lastSourcePosition = @sourcePosition
      {done} = @next()
      break if done

    return if @clipping?

    overshoot = position.column - lastSourcePosition.column
    lastPosition.column += overshoot
    @transformBuffer.reset(lastPosition, position)
    @position = lastPosition
    @sourcePosition = position

  getPosition: ->
    @position.copy()

  getSourcePosition: ->
    @sourcePosition.copy()
