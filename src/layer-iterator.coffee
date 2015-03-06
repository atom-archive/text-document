{EOF, Newline} = require "./symbols"
Point = require "./point"

module.exports =
class LayerIterator
  constructor: (@layer, sourceIterator) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformDelegate = new TransformDelegate(sourceIterator)

  next: ->
    unless @transformDelegate.bufferedOutputs.length > 0
      @layer.transform.operate(@transformDelegate)
    {@position, @sourcePosition, content} = @transformDelegate.bufferedOutputs.shift()
    if content is EOF
      {done: true}
    else
      {done: false, value: content}

  seek: (position) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformDelegate.reset(@position, @sourcePosition)
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
    @transformDelegate.reset(@position, @sourcePosition)

  seekToSourcePosition: (position) ->
    @position = Point.zero()
    @sourcePosition = Point.zero()
    @transformDelegate.reset(@position, @sourcePosition)
    return if position.isZero()

    until @sourcePosition.compare(position) >= 0
      lastPosition = @position
      lastSourcePosition = @sourcePosition
      {done} = @next()
      break if done

    overshoot = position.column - lastSourcePosition.column
    lastPosition.column += overshoot
    @transformDelegate.reset(lastPosition, position)
    @position = lastPosition
    @sourcePosition = position

  getPosition: ->
    @position

  getSourcePosition: ->
    @sourcePosition

class TransformDelegate
  constructor: (@sourceIterator) ->
    @reset(Point.zero(), Point.zero())

  reset: (position, sourcePosition) ->
    @position = position
    @sourcePosition = sourcePosition
    @bufferedOutputs = []
    @bufferedSourceOutput = null
    @sourceIterator.seek(sourcePosition)

  read: =>
    @bufferedSourceOutput or= @sourceIterator.next().value

  consume: (count) =>
    @sourcePosition.column += count
    @bufferedSourceOutput = @bufferedSourceOutput.substring(count)

  produce: (output) =>
    switch output
      when EOF
        null
      when Newline
        @position.column = 0
        @position.row++
      else
        @position.column += output.length

    @bufferedOutputs.push(
      content: output
      position: @position.copy()
      sourcePosition: @sourcePosition.copy()
    )
