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
      {value, done} = @regionMapIterator.next()
      if value.content?
        @position = @regionMapIterator.getPosition()
        return {value: value.content, done}

    @sourceIterator.seek(@position)
    next = @sourceIterator.next()
    {value, done} = next

    if @layer.contentOverlapsActiveRegion(@position, value)
      @regionMapIterator.seek(@position)
      extent = Point(0, value.length ? 0)
      @regionMapIterator.splice(extent, {extent, content: value})

    @position = @sourceIterator.getPosition()
    next

  seek: (@position) ->

  getPosition: ->
    @position
