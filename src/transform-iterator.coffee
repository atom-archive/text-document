{EOF, Newline} = require "./symbols"
Point = require "./point"

module.exports =
class TransformIterator
  constructor: (@transform, @sourceIterator) ->
    @bufferedOutputs = []
    @sourcePosition = Point.zero()
    @targetPosition = Point.zero()

    @transformSource =
      consume: @consumeSource.bind(this)
      read: @readSource.bind(this)
    @transformTarget =
      produce: @produce.bind(this)

  read: ->
    unless @bufferedOutputs.length > 0
      @transform.operate(@transformSource, @transformTarget)
    @bufferedOutputs.shift()

  ##
  # Transform Source
  ##

  readSource: ->
    @bufferedChunk ?= @sourceIterator.read()

  consumeSource: (count) ->
    @sourcePosition.column += count
    @bufferedChunk = @bufferedChunk.slice(count)
    @bufferedChunk = null if @bufferedChunk is ""

  ##
  # Transform Target
  ##

  produce: (output) ->
    switch output
      when EOF
        null
      when Newline
        @targetPosition.column = 0
        @targetPosition.row++
      else
        @targetPosition.column += output.length
    @bufferedOutputs.push(output)
