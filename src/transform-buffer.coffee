Point = require "./point"

CLIPPING__OPEN_INTERVAL = Symbol('clipping (open interval)')

module.exports =
class TransformBuffer
  constructor: (@transformer, @sourceIterator) ->
    @reset(Point.zero(), Point.zero())
    @transformContext = {
      clipping: open: CLIPPING__OPEN_INTERVAL
      read: @read.bind(this)
      getPosition: @getPosition.bind(this)
      transform: @transform.bind(this)
    }

  next: ->
    @inputIndex = 0
    @transformer.operate(@transformContext) unless @outputs.length > 0
    @outputs.shift()

  reset: (position, sourcePosition) ->
    @position = position.copy()
    @sourcePosition = sourcePosition.copy()
    @outputs = []
    @inputs = []
    @inputIndex = 0

  read: ->
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

  getPosition: ->
    @position.copy()

  transform: (consumedCount, producedContent, producedExtent, clipping) ->
    if producedContent?
      @consume(consumedCount)
      producedExtent ?= Point(0, producedContent.length)
      @produce(producedContent, producedExtent, clipping)
    else
      startSourcePosition = @sourcePosition.copy()
      consumedContent = @consume(consumedCount)
      consumedExtent = @sourcePosition.traversalFrom(startSourcePosition)
      @produce(consumedContent, consumedExtent, clipping)

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

  produce: (content, extent, clipping) ->
    @position = @position.traverse(extent)
    @outputs.push(
      content: content
      position: @position.copy()
      sourcePosition: @sourcePosition.copy()
      clipping: clipping
    )
