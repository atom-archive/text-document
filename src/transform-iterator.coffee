{EOF, Newline, Character} = require "./symbols"
Point = require "./point"

module.exports =
class TransformIterator
  constructor: (@layer, sourceIterator) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformBuffer = new TransformBuffer(@layer.transform, sourceIterator)

  next: ->
    {@position, @sourcePosition, content} = @transformBuffer.next()
    if content is EOF
      {done: true}
    else
      {done: false, value: content}

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

  produce: (output) =>
    switch output
      when EOF
        null
      when Newline
        @position.column = 0
        @position.row++
      else
        if output instanceof Character
          @position.column++
          output = output.string
        else
          @position.column += output.length

    @outputs.push(
      content: output
      position: @position.copy()
      sourcePosition: @sourcePosition.copy()
    )
