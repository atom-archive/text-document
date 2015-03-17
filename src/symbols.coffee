class Character
  constructor: (@string) ->

module.exports =
  EOF: Symbol("EOF")
  Newline: Symbol("Newline")
  Character: Character
