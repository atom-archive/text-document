{EOF, Newline} = require "./symbols"
Point = require "./point"

module.exports =
class LayerIterator
  constructor: (@layer, sourceIterator) ->
    @transformDelegate = new TransformDelegate(sourceIterator)
    @position = Point.zero()
    @sourcePosition = Point.zero()

  next: ->
    unless @transformDelegate.bufferedOutputs.length > 0
      @layer.transform.operate(@transformDelegate)
    @position = @transformDelegate.bufferedPositions.shift()
    @sourcePosition = @transformDelegate.bufferedSourcePositions.shift()
    value = @transformDelegate.bufferedOutputs.shift()
    if value is EOF
      {done: true}
    else
      {value, done: false}

  seek: (position) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformDelegate.reset(@position, @sourcePosition)
    return if position.isZero()

    until @position.compare(position) >= 0
      lastReadPosition = @position
      lastReadSourcePosition = @sourcePosition
      {value, done} = @next()
      return if done

    unless @position.compare(position) is 0
      overshoot = position.column - lastReadPosition.column
      lastReadSourcePosition.column += overshoot
      @position = position
      @sourcePosition = lastReadSourcePosition
    @transformDelegate.reset(@position, @sourcePosition)

  seekToSourcePosition: (position) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformDelegate.reset(@position, @sourcePosition)
    return if position.isZero()

    until @sourcePosition.compare(position) >= 0
      lastReadPosition = @position
      lastReadSourcePosition = @sourcePosition
      {value, done} = @next()
      break if done

    overshoot = position.column - lastReadSourcePosition.column
    lastReadPosition.column += overshoot
    @transformDelegate.reset(lastReadPosition, position)
    @position = lastReadPosition
    @sourcePosition = position

  getPosition: ->
    @position

  getSourcePosition: ->
    @sourcePosition

class TransformDelegate
  constructor: (@sourceIterator) ->
    @reset(Point.zero(), Point.zero())

  reset: (position, sourcePosition) ->
    @sourceIterator.seek(sourcePosition)
    @position = position
    @sourcePosition = sourcePosition
    @bufferedSourceOutput = null
    @bufferedOutputs = []
    @bufferedPositions = []
    @bufferedSourcePositions = []

  read: =>
    @bufferedSourceOutput ?= @sourceIterator.next().value

  consume: (count) =>
    @sourcePosition.column += count
    @bufferedSourceOutput = @bufferedSourceOutput.slice(count)
    @bufferedSourceOutput = null if @bufferedSourceOutput is ""

  produce: (output) =>
    switch output
      when EOF
        null
      when Newline
        @position.column = 0
        @position.row++
      else
        @position.column += output.length

    @bufferedSourcePositions.push(@sourcePosition.copy())
    @bufferedPositions.push(@position.copy())
    @bufferedOutputs.push(output)
