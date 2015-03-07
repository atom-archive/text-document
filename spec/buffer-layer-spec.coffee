Point = require "../src/point"
SpyLayer = require "./spy-layer"
BufferLayer = require "../src/buffer-layer"

describe "BufferLayer", ->
  describe "::getText()", ->
    it "returns the entire input text", ->
      source = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(source)

      expect(buffer.getText()).toBe "abcdefghijkl"
      expect(source.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", null]

      expect(buffer.getText()).toBe "abcdefghijkl"

  describe "::slice(start, size)", ->
    it "returns a substring of the input text with the given start index and size", ->
      source = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(source)

      expect(buffer.slice(Point(0, 1), Point(0, 3))).toBe "bcd"
      expect(source.getRecordedReads()).toEqual ["bcd"]
      source.reset()

      expect(buffer.slice(Point(0, 2), Point(0, 4))).toBe "cdef"
      expect(source.getRecordedReads()).toEqual ["cde", "fgh"]

  describe "iteration", ->
    it "returns an iterator into the buffer", ->
      source = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(source)
      iterator = buffer[Symbol.iterator]()
      iterator.seek(Point(0, 3))

      expect(iterator.next()).toEqual(value:"def", done: false)
      expect(iterator.getPosition()).toEqual(Point(0, 6))

      expect(iterator.next()).toEqual(value:"ghi", done: false)
      expect(iterator.getPosition()).toEqual(Point(0, 9))

      expect(iterator.next()).toEqual(value:"jkl", done: false)
      expect(iterator.getPosition()).toEqual(Point(0, 12))

      expect(iterator.next()).toEqual(done: true)
      expect(iterator.getPosition()).toEqual(Point(0, 12))

      expect(source.getRecordedReads()).toEqual ["def", "ghi", "jkl", null]
      source.reset()

      iterator.seek(Point(0, 5))
      expect(iterator.next()).toEqual(value:"fgh", done: false)

  describe "::setActiveRegion(start, end)", ->
    it "causes the buffer to cache the text within the given boundaries", ->
      source = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(source)

      buffer.getText()
      expect(source.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", null]
      source.reset()

      buffer.getText()
      expect(source.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", null]
      source.reset()

      buffer.setActiveRegion(Point(0, 3), Point(0, 9))

      buffer.getText()
      expect(source.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", null]
      source.reset()

      buffer.getText()
      expect(source.getRecordedReads()).toEqual ["abc", null]

    it "allows the region to be retrieved with ::getActiveRegion", ->
      source = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(source)
      expect(buffer.getActiveRegion()).toEqual([Infinity, -Infinity])

      buffer.setActiveRegion(Point(0, 3), Point(0, 9))
      expect(buffer.getActiveRegion()).toEqual([Point(0, 3), Point(0, 9)])
