{EOF} = require "./symbols"

module.exports =
class CharactersIterator
  constructor: (@text) ->
    @position = 0

  next: ->
    if @position is @text.length
      {value: EOF, done: true}
    else
      @position = @text.length
      {value: @text, done: false}

  seek: (@position) ->
