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
    @position

  getSourcePosition: ->
    @sourcePosition

class TransformBuffer
  constructor: (@transform, @sourceIterator) ->
    @reset(Point.zero(), Point.zero())

  next: ->
    @transform.operate(this) unless @outputs.length > 0
    @outputs.shift()

  reset: (position, sourcePosition) ->
    @position = position
    @sourcePosition = sourcePosition
    @outputs = []
    @currentSourceOutput = null
    @sourceIterator.seek(sourcePosition)

  read: =>
    @currentSourceOutput or= @sourceIterator.next().value

  consume: (count) =>
    @sourcePosition.column += count
    @currentSourceOutput = @currentSourceOutput.substring(count)

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

  produceCharacters: (output) =>
    @position.column += output.length
    @outputs.push(
      content: output
      position: @position.copy()
      sourcePosition: @sourcePosition.copy()
    )
