Point = require "../src/point"
StringLayer = require "../src/string-layer"
MutationLayer = require "../src/mutation-layer"
SpyLayer = require "./spy-layer"
Random = require "random-seed"

describe "MutationLayer", ->
  describe "::slice(start, end)", ->
    it "returns the content between the given start and end positions", ->
      source = new SpyLayer("abcdefghijkl", 3)
      mutationBuffer = new MutationLayer(source)
      mutationBuffer.splice(Point(0, 0), Point(0, 3), "123")

      expect(mutationBuffer.slice(Point(0, 1), Point(0, 3))).toBe "23"
      expect(source.getRecordedReads()).toEqual ["def"]
      source.reset()

      expect(mutationBuffer.slice(Point(0, 2), Point(0, 8))).toBe "3defgh"
      expect(source.getRecordedReads()).toEqual ["def", "ghi"]

    it "returns the entire input text when no bounds are given", ->
      source = new SpyLayer("abcdefghijkl", 3)
      mutationBuffer = new MutationLayer(source)
      mutationBuffer.splice(Point(0, 0), Point(0, 3), "123")

      expect(mutationBuffer.slice()).toBe "123defghijkl"
      expect(source.getRecordedReads()).toEqual ["def", "ghi", "jkl", undefined]

  describe "::splice(start, extent, content)", ->
    it "replaces the extent at the given position with the given content", ->
      source = new SpyLayer("abcdefghijkl", 3)
      mutationBuffer = new MutationLayer(source)

      mutationBuffer.splice(Point(0, 2), Point(0, 3), "123")

      expect(mutationBuffer.slice()).toBe "ab123fghijkl"

  describe "iteration", ->
    describe "when part of the content was spliced", ->
      it "iterates the spliced content first, falling back to source layer", ->
        source = new SpyLayer("abcdefghijkl", 3)
        mutationBuffer = new MutationLayer(source)
        mutationBuffer.splice(Point(0, 3), Point(0, 3), "123")
        mutationBuffer.splice(Point(0, 7), Point(0, 3), "456")
        iterator = mutationBuffer.buildIterator()
        iterator.seek(Point(0, 3))

        expect(iterator.next()).toEqual(value:"123", done: false)
        expect(iterator.getPosition()).toEqual(Point(0, 6))

        expect(iterator.next()).toEqual(value:"g", done: false)
        expect(iterator.getPosition()).toEqual(Point(0, 7))

        expect(iterator.next()).toEqual(value:"456", done: false)
        expect(iterator.getPosition()).toEqual(Point(0, 10))

        expect(iterator.next()).toEqual(value:"kl", done: false)
        expect(iterator.getPosition()).toEqual(Point(0, 12))

        expect(iterator.next()).toEqual(value: undefined, done: true)
        expect(iterator.getPosition()).toEqual(Point(0, 12))

        expect(source.getRecordedReads()).toEqual ["ghi", "kl", undefined]
        source.reset()

        iterator.seek(Point(0, 5))
        expect(iterator.next()).toEqual(value:"3", done: false)

    describe "when no content was spliced", ->
      it "iterates transparently over the source layer", ->
        source = new SpyLayer("abcdefghijkl", 3)
        mutationBuffer = new MutationLayer(source)
        iterator = mutationBuffer.buildIterator()
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

  describe "randomized mutations", ->
    it "behaves as if it were reading and writing directly to the underlying layer", ->
      for i in [0..30] by 1
        seed = Date.now()
        # seed = 1426552034823
        random = new Random(seed)

        oldContent = "abcdefghijklmnopqrstuvwxyz"
        source = new StringLayer(oldContent)
        mutationBuffer = new MutationLayer(source)
        reference = new StringLayer(oldContent)

        for j in [0..10] by 1
          currentContent = mutationBuffer.slice()
          newContentLength = random(20)
          newContent = (oldContent[random(26)] for k in [0..newContentLength]).join("").toUpperCase()

          startColumn = random(currentContent.length)
          endColumn = random.intBetween(startColumn, currentContent.length)
          start = Point(0, startColumn)
          extent = Point(0, endColumn - startColumn)

          # console.log mutationBuffer.slice()
          # console.log "mutationBuffer.splice(#{start}, #{extent}, #{newContent})"

          reference.splice(start, extent, newContent)
          mutationBuffer.splice(start, extent, newContent)

          expect(mutationBuffer.slice()).toBe(reference.slice(), "Seed: #{seed}, Iteration: #{j}")
          return unless mutationBuffer.slice() is reference.slice()
