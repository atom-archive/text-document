Point = require "./point"

module.exports =
class BufferLayer
  constructor: (@source) ->
    @bufferedRegions = []
    @activeRegionStart = Infinity
    @activeRegionEnd = -Infinity

  getText: ->
    @slice(Point.zero(), Point.infinity())

  slice: (start, size) ->
    text = ""
    iterator = @[Symbol.iterator]()
    iterator.seek(start)
    until text.length >= size.column
      {value, done} = iterator.next()
      break if done
      text += value
    text.slice(0, size.column)

  @::[Symbol.iterator] = ->
    new Iterator(this, @source[Symbol.iterator]())

  setActiveRegion: (start, end) ->
    @activeRegionStart = start
    @activeRegionEnd = end

  getActiveRegion: ->
    [@activeRegionStart, @activeRegionEnd]

  getBufferedText: ({column}) ->
    for region in @bufferedRegions
      break if region.start > column
      if region.start <= column < region.start + region.content.length
        return region.content.slice(column - region.start)
    null

  addBufferedText: ({column}, chunk) ->
    return unless @activeRegionStart.column <= column <= @activeRegionEnd.column
    for region, i in @bufferedRegions
      return if region.start is column
      if region.start > column
        @bufferedRegions.splice(i, 0, new BufferedRegion(column, chunk))
        return
    @bufferedRegions.push(new BufferedRegion(column, chunk))

class Iterator
  constructor: (@layer, @sourceIterator) ->
    @position = Point.zero()

  next: ->
    unless chunk = @layer.getBufferedText(@position)
      @sourceIterator.seek(@position)
      next = @sourceIterator.next()
      return next if next.done
      chunk = next.value
      @layer.addBufferedText(@position, chunk)

    @position.column += chunk.length
    {done: false, value: chunk}

  seek: (@position) ->
    @sourceIterator.seek(@position)

  getPosition: ->
    @position

class BufferedRegion
  constructor: (@start, @content) ->
