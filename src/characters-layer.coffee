CharactersIterator = require "./characters-iterator"

module.exports =
class CharactersLayer
  constructor: (@content) ->

  @::[Symbol.iterator] = ->
    new CharactersIterator(@content)
