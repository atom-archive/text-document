{Emitter} = require "event-kit"
{EOF} = require "./symbols"
Point = require "./point"

module.exports =
class StringLayer
  constructor: (@content) ->
    @emitter = new Emitter

  @::[Symbol.iterator] = ->
    new Iterator(this)

  slice: (start = Point.zero(), end = Point.infinity()) ->
    text = ""
    iterator = @[Symbol.iterator]()
    iterator.seek(start)
    until text.length >= end.column
      {value, done} = iterator.next()
      break if done
      text += value
    text.slice(0, end.column)

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

class Iterator
  constructor: (@layer) ->
    @seek(Point.zero())

  next: ->
    result = if @position.column >= @layer.content.length
      {value: EOF, done: true}
    else
      {value: @layer.content.substring(@position.column), done: false}
    @position = Point(0, @layer.content.length)
    result

  seek: (@position) ->

  getPosition: ->
    @position
