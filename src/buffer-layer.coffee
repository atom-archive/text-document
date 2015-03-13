Point = require "./point"
RegionMap = require "./region-map"

module.exports =
class BufferLayer
  constructor: (@source) ->
    @bufferedContent = new RegionMap
    @activeRegionStart = null
    @activeRegionEnd = null

  slice: (start = Point.zero(), end = Point.infinity()) ->
    text = ""
    iterator = @[Symbol.iterator]()
    iterator.seek(start)
    until text.length >= end.column
      {value, done} = iterator.next()
      break if done
      text += value
    text.slice(0, end.column)

  splice: (start, extent, content) ->
    iterator = @[Symbol.iterator]()
    iterator.seek(start)
    iterator.splice(extent, content)

  @::[Symbol.iterator] = ->
    new Iterator(this, @source[Symbol.iterator](), @bufferedContent[Symbol.iterator]())

  setActiveRegion: (start, end) ->
    @activeRegionStart = start
    @activeRegionEnd = end

  contentOverlapsActiveRegion: ({column}, content) ->
    return false unless @activeRegionStart? and @activeRegionEnd?
    not (column + content.length < @activeRegionStart.column) and
      not (column > @activeRegionEnd.column)

class Iterator
  constructor: (@layer, @sourceIterator, @regionMapIterator) ->
    @position = Point.zero()

  next: ->
    if @regionMapIterator.getPosition().compare(@position) <= 0
      @regionMapIterator.seek(@position)
      next = @regionMapIterator.next()
      if next.value?
        @position = @regionMapIterator.getPosition()
        return {value: next.value, done: next.done}

    @sourceIterator.seek(@position)
    next = @sourceIterator.next()

    sourceOvershoot = @sourceIterator.getPosition().traversalFrom(@regionMapIterator.getPosition())
    if sourceOvershoot.compare(Point.zero()) > 0
      next.value = next.value.substring(0, next.value.length - sourceOvershoot.column)
      nextPosition = @regionMapIterator.getPosition()
    else
      nextPosition = @sourceIterator.getPosition()

    if @layer.contentOverlapsActiveRegion(@position, next.value)
      @regionMapIterator.seek(@position)
      extent = Point(0, next.value.length ? 0)
      @regionMapIterator.splice(extent, next.value)

    @position = nextPosition
    next

  seek: (@position) ->

  getPosition: ->
    @position

  splice: (extent, content) ->
    @regionMapIterator.seek(@position)
    @regionMapIterator.splice(extent, content)
