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
          id = idCounter++
          [start, end] = getRange()
          # console.log "#{j}: insert(#{id}, #{start}, #{end})"
          markerIndex.insert(id, start, end)
          markers.push({id, start, end})

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
