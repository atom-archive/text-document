Point = require "../src/point"
StringLayer = require "../spec/string-layer"
BufferLayer = require "../src/buffer-layer"
SpyLayer = require "./spy-layer"
Random = require "random-seed"
{getAllIteratorValues, currentSpecFailed} = require "./spec-helper"

describe "BufferLayer", ->
  describe "iterator", ->
    describe "::next()", ->
      it "caches text from the underlying layer within the active region", ->
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

    getSplice = (random, length) ->
      operation = random(10)
      start = random(length)
      oldLength = random((length - start) / 2)
      newLength = random(20)
      newContent = (alphabet[random(26)].toUpperCase() for k in [0..newLength]).join("")

      # 60% insertions, 20% deletions, 20% replacements
      if operation < 6
        [start, 0, newContent]
      else if operation < 8
        [start, oldLength, ""]
      else
        [start, oldLength, newContent]

    it "behaves as if it were reading and writing directly to the underlying layer", ->
      for i in [0..20] by 1
        seed = Date.now()
        # seed = 1430431912858
        # console.log 'seed', seed
        random = new Random(seed)

        oldContent = Array(4).join(alphabet)
        reference = new StringLayer(oldContent)
        buffer = new BufferLayer(new StringLayer(oldContent))

        for j in [0..50] by 1
          [startColumn, columnCount, newContent] = getSplice(random, buffer.slice().length)
          start = Point(0, startColumn)
          extent = Point(0, columnCount)

          # console.log "#{j}: splice(#{start}, #{extent}, '#{newContent}')"

          reference.splice(start, extent, newContent)
          buffer.splice(start, extent, newContent)

          # console.log ""
          # console.log buffer.patch.rootNode.toString()
          # console.log ""
          # console.log buffer.slice()
          # console.log ""

          expect(buffer.slice()).toBe(reference.slice(), "Seed: #{seed}, Iteration: #{j}")
          return if currentSpecFailed()
