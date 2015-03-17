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
    @sourcePosition = Point.zero()

  next: ->
    comparison = @regionMapIterator.getPosition().compare(@position)
    if comparison <= 0
      @regionMapIterator.seek(@position) if comparison < 0
      next = @regionMapIterator.next()
      if next.value?
        @position = @regionMapIterator.getPosition()
        @sourcePosition = @regionMapIterator.getSourcePosition()
        return {value: next.value, done: next.done}

    @sourceIterator.seek(@sourcePosition)
    next = @sourceIterator.next()
    nextSourcePosition = @sourceIterator.getPosition()

    sourceOvershoot = @sourceIterator.getPosition().traversalFrom(@regionMapIterator.getSourcePosition())
    if sourceOvershoot.compare(Point.zero()) > 0
      next.value = next.value.substring(0, next.value.length - sourceOvershoot.column)
      nextPosition = @regionMapIterator.getPosition()
    else
      nextPosition = @position.traverse(nextSourcePosition.traversalFrom(@sourcePosition))

    if @layer.contentOverlapsActiveRegion(@position, next.value)
      @regionMapIterator.seek(@position)
      extent = Point(0, next.value.length ? 0)
      @regionMapIterator.splice(extent, next.value)

    @sourcePosition = nextSourcePosition
    @position = nextPosition
    next

  seek: (@position) ->
    @regionMapIterator.seek(@position)
    @sourcePosition = @regionMapIterator.getSourcePosition()
    @sourceIterator.seek(@sourcePosition)

  getPosition: ->
    @position

  splice: (extent, content) ->
    @regionMapIterator.seek(@position)
    @regionMapIterator.splice(extent, content)
