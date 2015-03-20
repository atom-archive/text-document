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

    unless @sourcePosition.compare(position) is 0
      overshoot = position.column - lastSourcePosition.column
      lastPosition.column += overshoot
      @position = lastPosition
      @sourcePosition = position

    @transformBuffer.reset(lastPosition, position)

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

  consume: (count) =>
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

  passThrough: (count) =>
    startSourcePosition = @sourcePosition.copy()
    content = @consume(count)
    @produceCharacters(content, @sourcePosition.traversalFrom(startSourcePosition))

  produceNewline: =>
    @position.column = 0
    @position.row++
    @outputs[@outputs.length - 1].position = @position.copy()

  produceCharacter: (output) =>
    @position.column++
    @outputs.push(
      content: output
      position: @position.copy()
      sourcePosition: @sourcePosition.copy()
    )

  produceCharacters: (output, traversal = Point(0, output.length)) =>
    @position = @position.traverse(traversal)
    @outputs.push(
      content: output
      position: @position.copy()
      sourcePosition: @sourcePosition.copy()
    )

  getPosition: =>
    @position.copy()
