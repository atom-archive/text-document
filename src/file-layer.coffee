fs = require "fs"
Point = require "./point"

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
    @position = Point.zero()

  next: ->
    if chunk = @store.getChunk(@bytePosition)
      @position.column += chunk.length
      @bytePosition += Buffer.byteLength(chunk)
      {done: false, value: chunk}
    else
      {done: true}

  seek: (position) ->
    if @position.column > position.column
      @bytePosition = 0
      @position.column = 0

    until @position.column is position.column
      if chunk = @store.getChunk(@bytePosition)
        chunk = chunk.substring(0, position.column - @position.column)
        @bytePosition += Buffer.byteLength(chunk)
        @position.column += chunk.length
      else
        break

  getPosition: ->
    @position.copy()
