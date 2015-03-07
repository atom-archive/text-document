module.exports =
class BufferLayer
  constructor: (@source) ->
    @bufferedRegions = []
    @activeRegionStart = Infinity
    @activeRegionEnd = -Infinity

  getText: ->
    @slice(0, Infinity)

  slice: (start, size) ->
    text = ""
    iterator = @[Symbol.iterator]()
    iterator.seek(start)
    until text.length >= size
      {value, done} = iterator.next()
      break if done
      text += value
    text.slice(0, size)

  @::[Symbol.iterator] = ->
    new Iterator(this, @source[Symbol.iterator]())

  setActiveRegion: (start, end) ->
    @activeRegionStart = start
    @activeRegionEnd = end

  getActiveRegion: ->
    [@activeRegionStart, @activeRegionEnd]

  getBufferedText: (position) ->
    for region in @bufferedRegions
      break if region.start > position
      if (region.start <= position) and (position < region.start + region.content.length)
        return region.content.slice(position - region.start)
    null

  addBufferedText: (position, chunk) ->
    return unless @activeRegionStart <= position and position <= @activeRegionEnd
    for region, i in @bufferedRegions
      return if region.start is position
      if region.start > position
        @bufferedRegions.splice(i, 0, new BufferedRegion(position, chunk))
        return
    @bufferedRegions.push(new BufferedRegion(position, chunk))

class Iterator
  constructor: (@layer, @sourceIterator) ->
    @position = 0

  next: ->
    unless chunk = @layer.getBufferedText(@position)
      @sourceIterator.seek(@position)
      next = @sourceIterator.next()
      return next if next.done
      chunk = next.value
      @layer.addBufferedText(@position, chunk)

    @position += chunk.length
    {done: false, value: chunk}

  seek: (@position) ->
    @sourceIterator.seek(@position)

  getPosition: ->
    @position

class BufferedRegion
  constructor: (@start, @content) ->
