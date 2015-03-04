{EOF, Newline} = require "./symbols"
Point = require "./point"

module.exports =
class TransformIterator
  constructor: (@transform, @sourceIterator) ->
    @bufferedOutputs = []
    @bufferedPositions = []
    @bufferedSourcePositions = []

    @bufferedSourcePosition = Point.zero()
    @bufferedPosition = Point.zero()

    @readSourcePosition = Point.zero()
    @readPosition = Point.zero()

    @transformSource =
      consume: @consumeSource.bind(this)
      read: @readSource.bind(this)
    @transformTarget =
      produce: @produce.bind(this)

  read: ->
    unless @bufferedOutputs.length > 0
      @transform.operate(@transformSource, @transformTarget)
    @readPosition = @bufferedPositions.shift()
    @readSourcePosition = @bufferedSourcePositions.shift()
    @bufferedOutputs.shift()

  getPosition: ->
    @readPosition

  getSourcePosition: ->
    @readSourcePosition

  ##
  # Transform Source
  ##

  readSource: ->
    @bufferedSourceOutput ?= @sourceIterator.read()

  consumeSource: (count) ->
    @bufferedSourcePosition.column += count
    @bufferedSourceOutput = @bufferedSourceOutput.slice(count)
    @bufferedSourceOutput = null if @bufferedSourceOutput is ""

  ##
  # Transform Target
  ##

  produce: (output) ->
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
