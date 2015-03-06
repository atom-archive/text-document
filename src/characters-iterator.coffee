{EOF} = require "./symbols"

module.exports =
class CharactersIterator
  constructor: (@charactersLayer) ->
    @seek(0)

  next: ->
    result = if @position >= @charactersLayer.content.length
      {value: EOF, done: true}
    else
      {value: @charactersLayer.content.slice(@position.column), done: false}
    @position = @charactersLayer.content.length
    result

  seek: (@position) ->
