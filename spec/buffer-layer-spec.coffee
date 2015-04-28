Point = require "../src/point"
StringLayer = require "../spec/string-layer"
BufferLayer = require "../src/buffer-layer"
SpyLayer = require "./spy-layer"
Random = require "random-seed"
{getAllIteratorValues, currentSpecFailed} = require "./spec-helper"

describe "BufferLayer", ->
  describe "::slice(start, end)", ->
    it "returns the content between the given start and end positions", ->
      inputLayer = new SpyLayer(new StringLayer("abcdefghijkl", 3))
      buffer = new BufferLayer(inputLayer)

      expect(buffer.slice(Point(0, 1), Point(0, 3))).toBe "bc"
      expect(inputLayer.getRecordedReads()).toEqual ["bcd"]
      inputLayer.reset()

      expect(buffer.slice(Point(0, 2), Point(0, 4))).toBe "cd"
      expect(inputLayer.getRecordedReads()).toEqual ["cde"]

    it "returns the entire inputLayer text when no bounds are given", ->
      inputLayer = new SpyLayer(new StringLayer("abcdefghijkl", 3))
      buffer = new BufferLayer(inputLayer)

      expect(buffer.slice()).toBe "abcdefghijkl"
      expect(inputLayer.getRecordedReads()).toEqual ["abc", "def", "ghi", "jkl", undefined]

  describe "iterator", ->
    describe "::next()", ->
      it "reads from the underlying layer", ->
        inputLayer = new SpyLayer(new StringLayer("abcdefghijkl", 3))
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
          inputLayer = new SpyLayer(new StringLayer("abcdefghijkl", 3))
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

          expect(getAllIteratorValues(buffer.buildIterator())).toEqual ["abc", "defghi", "jkl"]
          expect(inputLayer.getRecordedReads()).toEqual ["abc", "jkl", undefined]

    describe "::splice(start, extent, content)", ->
      it "replaces the extent at the given position with the given content", ->
        inputLayer = new StringLayer("abcdefghijkl", 3)
        buffer = new BufferLayer(inputLayer)

        iterator = buffer.buildIterator()
        iterator.seek(Point(0, 2))
        iterator.splice(Point(0, 3), "1234")

        expect(iterator.getPosition()).toEqual Point(0, 6)
        expect(iterator.getInputPosition()).toEqual Point(0, 5)
        expect(iterator.next()).toEqual {value: "fgh", done: false}

        expect(buffer.slice()).toBe "ab1234fghijkl"

        iterator.seek(Point(0, 11))
        iterator.splice(Point(0, 2), "HELLO")
        expect(buffer.slice()).toBe "ab1234fghijHELLO"

  describe "randomized mutations", ->
    alphabet = "abcdefghijklmnopqrstuvwxyz"

    getContent = (random) ->
      length = random(20)
      (alphabet[random(26)].toUpperCase() for k in [0..length]).join("")

    getSplice = (random, length) ->
      choice = random(10)
      startColumn = random(length)
      content = getContent(random)

      # 60% insertions, 40% replacements
      if choice < 6
        [startColumn, 0, content]
      else
        [startColumn, random((length - startColumn) / 2), content]

    it "behaves as if it were reading and writing directly to the underlying layer", ->
      for i in [0..20] by 1
        seed = Date.now()
        # seed = 1426552034823
        random = new Random(seed)

        oldContent = Array(5).join(alphabet)
        reference = new StringLayer(oldContent)
        buffer = new BufferLayer(new StringLayer(oldContent))

        for j in [0..50] by 1
          [startColumn, columnCount, newContent] = getSplice(random, buffer.slice().length)
          start = Point(0, startColumn)
          extent = Point(0, columnCount)

          # console.log buffer.slice()
          # console.log "buffer.splice(#{start}, #{extent}, #{newContent})"

          reference.splice(start, extent, newContent)
          buffer.splice(start, extent, newContent)

          expect(buffer.slice()).toBe(reference.slice(), "Seed: #{seed}, Iteration: #{j}")
          return if currentSpecFailed()
