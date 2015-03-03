{EOF} = require "./symbols"

module.exports =
class CharactersIterator
  constructor: (@text) ->
    @position = 0

  read: ->
    if @position is @text.length
      EOF
    else
      @position = @text.length
      @text
