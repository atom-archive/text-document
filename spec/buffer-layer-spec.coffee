Point = require "../src/point"
StringLayer = require "../src/string-layer"
BufferLayer = require "../src/buffer-layer"
SpyLayer = require "./spy-layer"
Random = require "random-seed"
{getAllIteratorValues} = require "./spec-helper"

describe "BufferLayer", ->
  describe "::slice(start, end)", ->
    it "returns the content between the given start and end positions", ->
      inputLayer = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(inputLayer)

      expect(buffer.slice(Point(0, 1), Point(0, 3))).toBe "bc"
      expect(inputLayer.getRecordedReads()).toEqual ["bcd"]
      inputLayer.reset()

      expect(buffer.slice(Point(0, 2), Point(0, 4))).toBe "cd"
      expect(inputLayer.getRecordedReads()).toEqual ["cde"]

    it "returns the entire inputLayer text when no bounds are given", ->
      inputLayer = new SpyLayer("abcdefghijkl", 3)
      buffer = new BufferLayer(inputLayer)

      expect(buffer.slice()).toBe "abcdefghijkl"
      expect(inputLayer.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", undefined]

  describe "iterator", ->
    describe "::next()", ->
      it "reads from the underlying layer", ->
        inputLayer = new SpyLayer("abcdefghijkl", 3)
        buffer = new BufferLayer(inputLayer)
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

        expect(inputLayer.getRecordedReads()).toEqual ["def", "ghi", "jkl", undefined]
        inputLayer.reset()

        iterator.seek(Point(0, 5))
        expect(iterator.next()).toEqual(value:"fgh", done: false)

      describe "when the buffer has an active region", ->
        it "caches the text within the region", ->
          inputLayer = new SpyLayer("abcdefghijkl", 3)
          buffer = new BufferLayer(inputLayer)

          expect(getAllIteratorValues(buffer.buildIterator())).toEqual ["abc", "def", "ghi", "jkl"]
          expect(inputLayer.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", undefined]
          inputLayer.reset()

          getAllIteratorValues(buffer.buildIterator())
          expect(inputLayer.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", undefined]
          inputLayer.reset()

          buffer.setActiveRegion(Point(0, 4), Point(0, 7))

          getAllIteratorValues(buffer.buildIterator())
          expect(inputLayer.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", undefined]
          inputLayer.reset()

          expect(getAllIteratorValues(buffer.buildIterator())).toEqual ["abc", "def", "ghi", "jkl"]
          expect(inputLayer.getRecordedReads()).toEqual ["abc", "jkl", undefined]

    describe "::splice(start, extent, content)", ->
      it "replaces the extent at the given position with the given content", ->
        inputLayer = new SpyLayer("abcdefghijkl", 3)
        buffer = new BufferLayer(inputLayer)

        iterator = buffer.buildIterator()
        iterator.seek(Point(0, 2))
        iterator.splice(Point(0, 3), "1234")

        expect(iterator.getPosition()).toEqual Point(0, 6)
        expect(iterator.getInputPosition()).toEqual Point(0, 5)
        expect(iterator.next()).toEqual {value: "fgh", done: false}

        expect(buffer.slice()).toBe "ab1234fghijkl"

        iterator.seek(Point(0, 11))
        iterator.splice(Point(0, 3), "HELLO")
        expect(buffer.slice()).toBe "ab1234fghijHELLO"

  describe "randomized mutations", ->
    it "behaves as if it were reading and writing directly to the underlying layer", ->
      for i in [0..30] by 1
        seed = Date.now()
        # seed = 1426552034823
        random = new Random(seed)

        oldContent = "abcdefghijklmnopqrstuvwxyz"
        inputLayer = new StringLayer(oldContent)
        buffer = new BufferLayer(inputLayer)
        reference = new StringLayer(oldContent)

        for j in [0..10] by 1
          currentContent = buffer.slice()
          newContentLength = random(20)
          newContent = (oldContent[random(26)] for k in [0..newContentLength]).join("").toUpperCase()

          startColumn = random(currentContent.length)
          endColumn = random.intBetween(startColumn, currentContent.length)
          start = Point(0, startColumn)
          extent = Point(0, endColumn - startColumn)

          # console.log buffer.slice()
          # console.log "buffer.splice(#{start}, #{extent}, #{newContent})"

          reference.splice(start, extent, newContent)
          buffer.splice(start, extent, newContent)

          expect(buffer.slice()).toBe(reference.slice(), "Seed: #{seed}, Iteration: #{j}")
          return unless buffer.slice() is reference.slice()
