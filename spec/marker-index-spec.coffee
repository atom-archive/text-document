Point = require "../src/point"
Range = require "../src/range"
MarkerIndex = require "../src/marker-index"
Random = require "random-seed"

{toEqualSet, expectSet} = require "./spec-helper"

describe "MarkerIndex", ->
  markerIndex = null

  beforeEach ->
    jasmine.addMatchers({toEqualSet})
    markerIndex = new MarkerIndex

  describe "::getRange(id)", ->
    it "returns the range for the given marker id", ->
      markerIndex.insert("a", Point(0, 2), Point(0, 5))
      markerIndex.insert("b", Point(0, 3), Point(0, 7))
      markerIndex.insert("c", Point(0, 4), Point(0, 4))
      markerIndex.insert("d", Point(0, 0), Point(0, 0))
      markerIndex.insert("e", Point(0, 0), Point(0, 0))

      expect(markerIndex.getRange("a")).toEqual Range(Point(0, 2), Point(0, 5))
      expect(markerIndex.getRange("b")).toEqual Range(Point(0, 3), Point(0, 7))
      expect(markerIndex.getRange("c")).toEqual Range(Point(0, 4), Point(0, 4))
      expect(markerIndex.getRange("d")).toEqual Range(Point(0, 0), Point(0, 0))
      expect(markerIndex.getRange("e")).toEqual Range(Point(0, 0), Point(0, 0))

      markerIndex.delete("e")
      markerIndex.delete("c")
      markerIndex.delete("a")

      expect(markerIndex.getRange("a")).toBeUndefined()
      expect(markerIndex.getRange("b")).toEqual Range(Point(0, 3), Point(0, 7))
      expect(markerIndex.getRange("c")).toBeUndefined()
      expect(markerIndex.getRange("d")).toEqual Range(Point(0, 0), Point(0, 0))
      expect(markerIndex.getRange("e")).toBeUndefined()

  describe "::findContaining(range)", ->
    it "returns the markers whose ranges contain the given range", ->
      markerIndex.insert("a", Point(0, 2), Point(0, 5))
      markerIndex.insert("b", Point(0, 3), Point(0, 7))

      # range queries
      expect(markerIndex.findContaining(Point(0, 1), Point(0, 3))).toEqualSet []
      expect(markerIndex.findContaining(Point(0, 2), Point(0, 4))).toEqualSet ["a"]
      expect(markerIndex.findContaining(Point(0, 3), Point(0, 4))).toEqualSet ["a", "b"]
      expect(markerIndex.findContaining(Point(0, 4), Point(0, 7))).toEqualSet ["b"]
      expect(markerIndex.findContaining(Point(0, 4), Point(0, 8))).toEqualSet []

      # point queries
      expect(markerIndex.findContaining(Point(0, 2))).toEqualSet ["a"]
      expect(markerIndex.findContaining(Point(0, 3))).toEqualSet ["a", "b"]
      expect(markerIndex.findContaining(Point(0, 5))).toEqualSet ["a", "b"]
      expect(markerIndex.findContaining(Point(0, 7))).toEqualSet ["b"]

  describe "::splice(position, oldExtent, newExtent)", ->
    describe "when the change has a non-empty old extent and new extent", ->
      it "updates markers based on the change", ->
        markerIndex.insert("preceding", Point(0, 3), Point(0, 4))
        markerIndex.insert("ending-at-start", Point(0, 3), Point(0, 5))
        markerIndex.insert("overlapping-start", Point(0, 4), Point(0, 6))
        markerIndex.insert("starting-at-start", Point(0, 5), Point(0, 7))
        markerIndex.insert("within", Point(0, 6), Point(0, 7))
        markerIndex.insert("surrounding", Point(0, 4), Point(0, 9))
        markerIndex.insert("ending-at-end", Point(0, 6), Point(0, 8))
        markerIndex.insert("overlapping-end", Point(0, 6), Point(0, 9))
        markerIndex.insert("starting-at-end", Point(0, 8), Point(0, 10))
        markerIndex.insert("following", Point(0, 9), Point(0, 10))

        markerIndex.splice(Point(0, 5), Point(0, 3), Point(0, 4))

        # Markers that preceded the change do not move.
        expect(markerIndex.getRange("preceding")).toEqual Range(Point(0, 3), Point(0, 4))

        # Markers that ended at the start of the change do not move.
        expect(markerIndex.getRange("ending-at-start")).toEqual Range(Point(0, 3), Point(0, 5))

        # Markers that overlapped the start of the change maintain their start
        # position, and now end at the end of the change.
        expect(markerIndex.getRange("overlapping-start")).toEqual Range(Point(0, 4), Point(0, 9))

        # Markers that start at the start of the change maintain their start
        # position.
        expect(markerIndex.getRange("starting-at-start")).toEqual Range(Point(0, 5), Point(0, 9))

        # Markers that were within the change become points at the end of the
        # change.
        expect(markerIndex.getRange("within")).toEqual Range(Point(0, 9), Point(0, 9))

        # Markers that surrounded the change maintain their start position and
        # their logical end position.
        expect(markerIndex.getRange("surrounding")).toEqual Range(Point(0, 4), Point(0, 10))

        # Markers that end at the end of the change maintain their logical end
        # position.
        expect(markerIndex.getRange("ending-at-end")).toEqual Range(Point(0, 9), Point(0, 9))

        # Markers that overlapped the end of the change now start at the end of
        # the change, and maintain their logical end position.
        expect(markerIndex.getRange("overlapping-end")).toEqual Range(Point(0, 9), Point(0, 10))

        # Markers that start at the end of the change maintain their logical
        # start and end positions.
        expect(markerIndex.getRange("starting-at-end")).toEqual Range(Point(0, 9), Point(0, 11))

        # Markers that followed the change maintain their logical start and end
        # positions.
        expect(markerIndex.getRange("following")).toEqual Range(Point(0, 10), Point(0, 11))

  describe "randomized mutations", ->
    [seed, random, markers, idCounter] = []

    it "maintains data structure invariants and returns correct query results", ->
      for i in [1..10]
        seed = Date.now() # paste the failing seed here to reproduce if there are failures
        random = new Random(seed)
        markers = []
        idCounter = 1
        markerIndex = new MarkerIndex

        for j in [1..10]
          # 80% insert, 20% delete
          if markers.length is 0 or random(10) > 2
            id = idCounter++
            [start, end] = getRange()
            # console.log "#{j}: insert(#{id}, #{start}, #{end})"
            markerIndex.insert(id, start, end)
            markers.push({id, start, end})
          else
            [{id}] = markers.splice(random(markers.length - 1), 1)
            markerIndex.delete(id)

          # console.log markerIndex.rootNode.toString()

          for {id, start, end} in markers
            expect(markerIndex.getStart(id)).toEqual start, "(Marker #{id}; Seed: #{seed})"
            expect(markerIndex.getEnd(id)).toEqual end, "(Marker #{id}; Seed: #{seed})"

          for k in [1..10]
            [queryStart, queryEnd] = getRange()
            # console.log "#{k}: findContaining(#{queryStart}, #{queryEnd})"
            expect(markerIndex.findContaining(queryStart, queryEnd)).toEqualSet(getExpectedContaining(queryStart, queryEnd), "(Seed: #{seed})")

    getRange = ->
      start = Point(0, random(100))
      end = Point(0, random.intBetween(start.column, 100))
      [start, end]

    getExpectedContaining = (start, end) ->
      expected = []
      for marker in markers
        if marker.start.compare(start) <= 0 and end.compare(marker.end) <= 0
          expected.push(marker.id)
      expected
