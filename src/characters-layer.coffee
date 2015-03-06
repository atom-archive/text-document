CharactersIterator = require "./characters-iterator"

module.exports =
class CharactersLayer
  constructor: (@content) ->

  @::[Symbol.iterator] = ->
    new CharactersIterator(@content)

  splice: (position, extent, content) ->
    @assertValidPosition(position)
    @assertValidPosition(position.traverse(extent))
    @content =
      @content.substring(0, position.column) +
      content +
      @content.substring(position.column + extent.column)

  assertValidPosition: (position) ->
    unless position.row is 0 and 0 <= position.column <= @content.length
      throw new Error("Invalid position #{position}")
