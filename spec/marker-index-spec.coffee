Point = require "../src/point"
Range = require "../src/range"
MarkerIndex = require "../src/marker-index"

{expectSet} = require "./spec-helper"

fdescribe "MarkerIndex", ->
  markerIndex = null

  beforeEach ->
    markerIndex = new MarkerIndex

  describe "::findContaining(range)", ->
    it "returns the markers whose ranges contain the given range", ->
      markerIndex.insert("a", Point(0, 2), Point(0, 5))
      markerIndex.insert("b", Point(0, 3), Point(0, 7))

      # range queries
      expectSet markerIndex.findContaining(Point(0, 1), Point(0, 3)), []
      expectSet markerIndex.findContaining(Point(0, 2), Point(0, 4)), ["a"]
      expectSet markerIndex.findContaining(Point(0, 3), Point(0, 4)), ["a", "b"]
      expectSet markerIndex.findContaining(Point(0, 4), Point(0, 7)), ["b"]
      expectSet markerIndex.findContaining(Point(0, 4), Point(0, 8)), []

      # point queries
      expectSet markerIndex.findContaining(Point(0, 2)), ["a"]
      expectSet markerIndex.findContaining(Point(0, 3)), ["a", "b"]
      expectSet markerIndex.findContaining(Point(0, 5)), ["a", "b"]
      expectSet markerIndex.findContaining(Point(0, 7)), ["b"]
