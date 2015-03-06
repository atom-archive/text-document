{Emitter} = require "event-kit"
Point = require "./point"
CharactersIterator = require "./characters-iterator"

module.exports =
class CharactersLayer
  constructor: (@content) ->
    @emitter = new Emitter

  @::[Symbol.iterator] = ->
    new CharactersIterator(this)

  splice: (position, oldExtent, content) ->
    @assertValidPosition(position)
    @assertValidPosition(position.traverse(oldExtent))

    @emitter.emit("will-change", {position, oldExtent})

    @content =
      @content.substring(0, position.column) +
      content +
      @content.substring(position.column + oldExtent.column)

    @emitter.emit("did-change", {position, oldExtent, newExtent: Point(0, content.length)})

  onWillChange: (fn) ->
    @emitter.on("will-change", fn)

  onDidChange: (fn) ->
    @emitter.on("did-change", fn)

  assertValidPosition: (position) ->
    unless position.row is 0 and 0 <= position.column <= @content.length
      throw new Error("Invalid position #{position}")
