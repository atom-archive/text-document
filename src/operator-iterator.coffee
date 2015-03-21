Point = require "./point"

module.exports =
class OperatorIterator
  constructor: (@operator, @sourceIterator) ->
    @reset(Point.zero(), Point.zero())

  next: ->
    @inputIndex = 0
    @operator.operate(this) unless @outputs.length > 0
    @outputs.shift()

  reset: (position, sourcePosition) ->
    @position = position.copy()
    @sourcePosition = sourcePosition.copy()
    @outputs = []
    @inputs = []
    @inputIndex = 0
    debugger unless @sourceIterator.seek?
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
