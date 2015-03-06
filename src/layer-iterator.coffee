{EOF, Newline} = require "./symbols"
Point = require "./point"

module.exports =
class LayerIterator
  constructor: (@layer, @sourceIterator) ->
    @transformDelegate = new TransformDelegate(@sourceIterator)
    @readPosition = Point.zero()
    @readSourcePosition = Point.zero()

  next: ->
    unless @transformDelegate.bufferedOutputs.length > 0
      @layer.transform.operate(@transformDelegate)
    @readPosition = @transformDelegate.bufferedPositions.shift()
    @readSourcePosition = @transformDelegate.bufferedSourcePositions.shift()
    value = @transformDelegate.bufferedOutputs.shift()
    if value is EOF
      {done: true}
    else
      {value, done: false}

  seek: (position) ->
    @readPosition = Point.zero()
    @readSourcePosition = Point.zero()
    @sourceIterator.seek(@readSourcePosition)
    return if position.isZero()

    until @readPosition.compare(position) >= 0
      lastReadPosition = @readPosition
      lastReadSourcePosition = @readSourcePosition
      {value, done} = @next()
      return false if done

    overshoot = @readPosition.column - position.column
    lastReadSourcePosition.column += overshoot
    @sourceIterator.seek(lastReadSourcePosition)
    @readPosition = position
    true

  getPosition: ->
    @readPosition

  getSourcePosition: ->
    @readSourcePosition

class TransformDelegate
  constructor: (@sourceIterator) ->
    @bufferedSourcePosition = Point.zero()
    @bufferedPosition = Point.zero()
    @bufferedSourceOutput = null
    @bufferedOutputs = []
    @bufferedPositions = []
    @bufferedSourcePositions = []

  read: =>
    @bufferedSourceOutput ?= @sourceIterator.next().value

  consume: (count) =>
    @bufferedSourcePosition.column += count
    @bufferedSourceOutput = @bufferedSourceOutput.slice(count)
    @bufferedSourceOutput = null if @bufferedSourceOutput is ""

  produce: (output) =>
    switch output
      when EOF
        null
      when Newline
        @bufferedPosition.column = 0
        @bufferedPosition.row++
      else
        @bufferedPosition.column += output.length

    @bufferedSourcePositions.push(@bufferedSourcePosition.copy())
    @bufferedPositions.push(@bufferedPosition.copy())
    @bufferedOutputs.push(output)
