Point = require "./point"

module.exports =
class TransformIterator
  constructor: (@layer, sourceIterator) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformBuffer = new TransformBuffer(@layer.transform, sourceIterator)

  next: ->
    if next = @transformBuffer.next()
      {@position, @sourcePosition, content} = next
      {value: content, done: false}
    else
      {value: undefined, done: true}

  seek: (position) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformBuffer.reset(@position, @sourcePosition)
    return if position.isZero()

    until @position.compare(position) >= 0
      lastPosition = @position
      lastSourcePosition = @sourcePosition
      {done} = @next()
      return if done

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

    overshoot = position.column - lastSourcePosition.column
    lastPosition.column += overshoot
    @transformBuffer.reset(lastPosition, position)
    @position = lastPosition
    @sourcePosition = position

  getPosition: ->
    @position.copy()

  getSourcePosition: ->
    @sourcePosition.copy()

class TransformBuffer
  constructor: (@transform, @sourceIterator) ->
    @reset(Point.zero(), Point.zero())

  next: ->
    @inputIndex = 0
    @transform.operate(this) unless @outputs.length > 0
    @outputs.shift()

  reset: (position, sourcePosition) ->
    @position = position.copy()
    @sourcePosition = sourcePosition.copy()
    @outputs = []
    @inputs = []
    @inputIndex = 0
    @sourceIterator.seek(sourcePosition)

  read: =>
    if input = @inputs[@inputIndex]
      content = input.content
    else
      content = @sourceIterator.next().value
      @inputs.push(
        content: content
        sourcePosition: @sourceIterator.getPosition()
      )
    @inputIndex++
    content

  transduce: (consumedCount, producedContent, producedExtent) =>
    if producedContent?
      @consume(consumedCount)
      producedExtent ?= Point(0, producedContent.length)
      @produce(producedContent, producedExtent)
    else
      startSourcePosition = @sourcePosition.copy()
      consumedContent = @consume(consumedCount)
      consumedExtent = @sourcePosition.traversalFrom(startSourcePosition)
      @produce(consumedContent, consumedExtent)

  consume: (count) ->
    consumedContent = ""
    while count > 0
      if count >= @inputs[0].content.length
        {content, @sourcePosition} = @inputs.shift()
        consumedContent += content
        count -= content.length
        @inputIndex--
      else
        consumedContent += @inputs[0].content.substring(0, count)
        @inputs[0].content = @inputs[0].content.substring(count)
        @sourcePosition.column += count
        count = 0
    consumedContent

  produce: (content, extent) ->
    @position = @position.traverse(extent)
    @outputs.push(
      content: content
      position: @position.copy()
      sourcePosition: @sourcePosition.copy()
    )

  getPosition: =>
    @position.copy()
