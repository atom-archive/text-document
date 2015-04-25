Range = require "../src/range"
Point = require "../src/point"

describe "Range", ->
  describe "::negate()", ->
    it "should negate the start and end points", ->
      expect(Range([ 0,  0], [ 0,  0]).negate().isEqual([[ 0,  0], [ 0,  0]]))
      expect(Range([ 1,  2], [ 3,  4]).negate().isEqual([[-1, -2], [-3, -4]]))
      expect(Range([-1, -2], [-3, -4]).negate().isEqual([[ 1,  2], [ 3,  4]]))
      expect(Range([-1,  2], [ 3, -4]).negate().isEqual([[ 1, -2], [-3,  4]]))

  describe "::intersectsWith(other, [exclusive])", ->
    intersectsWith = (range1, range2, exclusive) ->
      range1 = Range.fromObject(range1)
      range1.intersectsWith(range2, exclusive)

    describe "when the exclusive argument is false (the default)", ->
      it "returns true if the ranges intersect, exclusive of their endpoints", ->
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 0], [1, 1]])).toBe false
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 1], [1, 2]])).toBe true
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 1], [1, 3]])).toBe true
        expect(intersectsWith([[1, 2], [3, 4]], [[3, 4], [4, 5]])).toBe true
        expect(intersectsWith([[1, 2], [3, 4]], [[3, 3], [4, 5]])).toBe true
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 5], [2, 2]])).toBe true
        expect(intersectsWith([[1, 2], [3, 4]], [[3, 5], [4, 4]])).toBe false
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 2], [1, 2]], true)).toBe false
        expect(intersectsWith([[1, 2], [3, 4]], [[3, 4], [3, 4]], true)).toBe false

    describe "when the exclusive argument is true", ->
      it "returns true if the ranges intersect, exclusive of their endpoints", ->
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 0], [1, 1]], true)).toBe false
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 1], [1, 2]], true)).toBe false
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 1], [1, 3]], true)).toBe true
        expect(intersectsWith([[1, 2], [3, 4]], [[3, 4], [4, 5]], true)).toBe false
        expect(intersectsWith([[1, 2], [3, 4]], [[3, 3], [4, 5]], true)).toBe true
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 5], [2, 2]], true)).toBe true
        expect(intersectsWith([[1, 2], [3, 4]], [[3, 5], [4, 4]], true)).toBe false
        expect(intersectsWith([[1, 2], [3, 4]], [[1, 2], [1, 2]], true)).toBe false
        expect(intersectsWith([[1, 2], [3, 4]], [[3, 4], [3, 4]], true)).toBe false

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
