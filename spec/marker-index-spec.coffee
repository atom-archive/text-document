Point = require "../src/point"
Range = require "../src/range"
MarkerIndex = require "../src/marker-index"

fdescribe "MarkerIndex", ->
  markerIndex = null

  beforeEach ->
    markerIndex = new MarkerIndex

  describe "::findContaining(range)", ->
    it "returns the markers whose ranges contain the given range", ->
      console.log markerIndex.rootNode.toString()

      markerIndex.insert("a", Point(0, 2), Point(0, 5))
      console.log markerIndex.rootNode.toString()

      markerIndex.insert("b", Point(0, 3), Point(0, 7))
      console.log markerIndex.rootNode.toString()

      expect(markerIndex.findContaining(Point(0, 1), Point(0, 3))).toEqual []
      expect(markerIndex.findContaining(Point(0, 2), Point(0, 4))).toEqual ["a"]

      return
      expect(markerIndex.findContaining(Point(0, 3), Point(0, 4))).toEqual ["a", "b"]
      expect(markerIndex.findContaining(Point(0, 4), Point(0, 7))).toEqual ["b"]
      expect(markerIndex.findContaining(Point(0, 4), Point(0, 8))).toEqual []
