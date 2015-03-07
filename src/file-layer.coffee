fs = require "fs"

module.exports =
class FileLayer
  constructor: (path, @chunkSize) ->
    @buffer = new Buffer(@chunkSize * 4)
    @fd = fs.openSync(path, 'r')

  destroy: ->
    fs.close(@fd)

  @::[Symbol.iterator] = ->
    new Iterator(this)

  getChunk: (byteOffset) ->
    bytesRead = fs.readSync(@fd, @buffer, 0, @buffer.length, byteOffset)
    if bytesRead > 0
      @buffer.toString('utf8', 0, bytesRead).substr(0, @chunkSize)
    else
      null

class Iterator
  constructor: (@store) ->
    @bytePosition = 0
    @charPosition = 0

  next: ->
    if chunk = @store.getChunk(@bytePosition)
      @charPosition += chunk.length
      @bytePosition += Buffer.byteLength(chunk)
      {done: false, value: chunk}
    else
      {done: true}

  seek: (position) ->
    if @charPosition > position
      @bytePosition = 0
      @charPosition = 0

    until @charPosition is position
      if chunk = @store.getChunk(@bytePosition)
        chunk = chunk.substring(0, position - @charPosition)
        @bytePosition += Buffer.byteLength(chunk)
        @charPosition += chunk.length
      else
        break

  getPosition: ->
    @charPosition
