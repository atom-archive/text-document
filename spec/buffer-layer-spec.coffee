Point = require "../src/point"
StringLayer = require "../src/string-layer"
BufferLayer = require "../src/buffer-layer"
SpyLayer = require "./spy-layer"
Random = require "random-seed"

describe "BufferLayer", ->
  describe "::slice(start, end)", ->
    it "returns the content between the given start and end positions", ->
      source = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(source)

      expect(buffer.slice(Point(0, 1), Point(0, 3))).toBe "bc"
      expect(source.getRecordedReads()).toEqual ["bcd"]
      source.reset()

      expect(buffer.slice(Point(0, 2), Point(0, 4))).toBe "cd"
      expect(source.getRecordedReads()).toEqual ["cde"]

    it "returns the entire input text when no bounds are given", ->
      source = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(source)

      expect(buffer.slice()).toBe "abcdefghijkl"
      expect(source.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", undefined]

  describe "iteration", ->
    it "returns an iterator into the buffer", ->
      source = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(source)
      iterator = buffer.buildIterator()
      iterator.seek(Point(0, 3))

      expect(iterator.next()).toEqual(value:"def", done: false)
      expect(iterator.getPosition()).toEqual(Point(0, 6))

      expect(iterator.next()).toEqual(value:"ghi", done: false)
      expect(iterator.getPosition()).toEqual(Point(0, 9))

      expect(iterator.next()).toEqual(value:"jkl", done: false)
      expect(iterator.getPosition()).toEqual(Point(0, 12))

      expect(iterator.next()).toEqual(value: undefined, done: true)
      expect(iterator.getPosition()).toEqual(Point(0, 12))

      expect(source.getRecordedReads()).toEqual ["def", "ghi", "jkl", undefined]
      source.reset()

      iterator.seek(Point(0, 5))
      expect(iterator.next()).toEqual(value:"fgh", done: false)

  describe "::setActiveRegion(start, end)", ->
    it "causes the buffer to cache the text within the given boundaries", ->
      source = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(source)

      expect(buffer.slice()).toBe "abcdefghijkl"
      expect(source.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", undefined]
      source.reset()

      expect(buffer.slice()).toBe "abcdefghijkl"
      expect(source.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", undefined]
      source.reset()

      buffer.setActiveRegion(Point(0, 4), Point(0, 7))

      expect(buffer.slice()).toBe "abcdefghijkl"
      expect(source.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", undefined]
      source.reset()

      expect(buffer.slice()).toBe "abcdefghijkl"
      expect(source.getRecordedReads()).toEqual ["abc", "jkl", undefined]
      source.reset()

      expect(buffer.slice(Point(0, 0), Point(0, 6))).toBe "abcdef"
      expect(source.getRecordedReads()).toEqual ["abc"]
