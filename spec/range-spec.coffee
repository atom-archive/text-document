Range = require "../src/range"
Point = require "../src/point"

describe "Range", ->
  describe "::containsPoint(point)", ->
    describe "when the 'exclusive' option is true", ->
      it "returns true if the given point is strictly between the range's endpoints", ->
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 1], true)).toBe false
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 2], true)).toBe true
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 4], true)).toBe false

    describe "when the 'exclusive' option is false or missing", ->
      it "returns true if the given point is strictly between the range's endpoints", ->
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 0])).toBe false
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 1])).toBe true
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 4])).toBe true
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 5])).toBe false
