Range = require "../src/range"
Point = require "../src/point"

describe "Range", ->
  describe "::copy()", ->
    it "returns a copy of the given range", ->
      expect(Range([1, 3], [3, 4]).copy()).toEqual Range([1, 3], [3, 4])
      expect(Range([1, 3], [2, 3]).copy()).toEqual [[1, 3], [2, 3]]

  describe "::negate()", ->
    it "should negate the start and end points", ->
      expect(Range([ 0,  0], [ 0,  0]).negate()).toEqual [[ 0,  0], [ 0,  0]]
      expect(Range([ 1,  2], [ 3,  4]).negate()).toEqual [[-1, -2], [-3, -4]]
      expect(Range([-1, -2], [-3, -4]).negate()).toEqual [[ 1,  2], [ 3,  4]]
      expect(Range([-1,  2], [ 3, -4]).negate()).toEqual [[ 1, -2], [-3,  4]]

  describe "::reverse()", ->
    it "returns a range with reversed start and end points", ->
      expect(Range(Point(0, 2), Point(3, 4)).reverse()).toEqual [[3, 4], [0, 2]]
      expect(Range([3, 4], [2, 3]).reverse()).toEqual [[2, 3], [3, 4]]

  describe "::isEmpty()", ->
    it "returns whether if start is equal to end", ->
      expect(Range([0, 0], [0, 0]).isEmpty()).toBe true
      expect(Range([2, 3], [4, 5]).isEmpty()).toBe false

  describe "::isSingleLine()", ->
    it "returns whether start row is equal to end row", ->
      expect(Range([2, 3], [3, 4]).isSingleLine()).toBe false
      expect(Range([1, 2], [1, 5]).isSingleLine()).toBe true

  describe "::getRowCount()", ->
    it "returns total number of rows in the given range", ->
      expect(Range([2, 3], [4, 4]).getRowCount()).toBe 3
      expect(Range([2, 4], [2, 6]).getRowCount()).toBe 1
      expect(Range([2, 4], [2, 1]).getRowCount()).toBe 1

      expect(Range([2, 5], [0, 5]).getRowCount()).toBe -1 #incorrect due to impl

  describe "::getRows()", ->
    it "returns the rows from start.row to end.row", ->
      expect(Range([2, 5], [7, 6]).getRows()).toEqual [2..7]
      expect(Range([2, 5], [2, 9]).getRows()).toEqual [2]
      expect(Range([5, 6], [0, 4]).getRows()).toEqual [5..0]

  describe "::freeze()", ->
    it "makes the range object immutable", ->
      expect(Object.isFrozen(Range([2, 4], [3, 5]).freeze())).toBe true
      expect(Object.isFrozen(Range([0, 0], [0, 0]).freeze())).toBe true

  describe "::union(otherRange)", ->
    it "returns a new range that contains this range and the given range", ->
      expect(Range([2, 3], [3, 3]).union(Range([3, 5], [4, 6]))).toEqual [[2, 3], [4, 6]]
      expect(Range([2, 4], [3, 5]).union([[3, 0], [4, 5]])).toEqual [[2, 4], [4, 5]]
      expect(Range([2, 4], [3, 4]).union([[1, 0], [2, 7]])).toEqual [[1, 0], [3, 4]]
      expect(Range([2, 4], [3, 4]).union([[1, 0], [4, 5]])).toEqual [[1, 0], [4, 5]]
      expect(Range([2, 4], [3, 4]).union([[1, 0], [2, 2]])).toEqual [[1, 0], [3, 4]]

      expect(Range([4, 3], [2, 3]).union([[2, 2], [0, 0]])).toEqual [[2, 2], [2, 3]]

  describe "::translate(startDelta, [endDelta])", ->
    it "translate start by startDelta and end by endDelta and returns the range", ->
      expect(Range([2, 3], [4, 5]).translate([1, 1])).toEqual [[3, 4], [5, 6]]
      expect(Range([1, 1], [3, 3]).translate([1, 1], [2, 2])).toEqual [[2, 2], [5, 5]]

  describe "::traverse(delta)", ->
    it "traverse start & end by delta and returns the range", ->
      expect(Range([1, 1], [3, 3]).traverse([1, 1])).toEqual [[2, 1], [4, 1]]
      expect(Range([2, 2], [2, 6]).traverse([0, 3])).toEqual [[2, 5], [2, 9]]

  describe "::compare(other)", ->
    it "returns -1 for <, 0 for =, 1 for > comparisions", ->
      expect(Range([1, 2], [2, 3]).compare([[1, 3], [4, 5]])).toBe -1
      expect(Range([3, 2], [3, 4]).compare([[1, 3], [4, 5]])).toBe  1
      expect(Range([1, 2], [2, 3]).compare([[1, 2], [4, 5]])).toBe  1
      expect(Range([1, 2], [2, 3]).compare([[1, 2], [1, 0]])).toBe -1
      expect(Range([1, 2], [2, 3]).compare([[1, 2], [2, 3]])).toBe  0

      expect(Range([2, 3], [1, 2]).compare([[4, 5], [1, 3]])).toBe -1
      expect(Range([3, 4], [3, 2]).compare([[4, 5], [1, 3]])).toBe -1
      expect(Range([2, 3], [1, 2]).compare([[4, 5], [1, 2]])).toBe -1
      expect(Range([2, 3], [1, 2]).compare([[1, 0], [1, 2]])).toBe  1

  describe "::isEqual(otherRange)", ->
    it "returns whether otherRange is equal to the given range", ->
      expect(Range([1, 2], [3, 4]).isEqual([[1, 2], [3, 4]])).toBe true
      expect(Range([1, 2], [3, 4]).isEqual([[1, 2], [3, 3]])).toBe false

  describe "::coversSameRows(otherRange)", ->
    it "returns whether start.row and end.row for given range and otherRange are equal", ->
      expect(Range([1, 2], [4, 5]).coversSameRows([[1, 3], [4, 7]])).toBe true
      expect(Range([1, 2], [4, 5]).coversSameRows([[2, 3], [4, 7]])).toBe false
      expect(Range([1, 2], [4, 5]).coversSameRows([[1, 3], [3, 7]])).toBe false

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

  describe "::intersectsRowRange(startRow, endRow)", ->
    it "returns whether there is a row in given range that lies between startRow and endRow", ->
      expect(Range([1, 2], [3, 5]).intersectsRowRange( 2,  4)).toBe true
      expect(Range([1, 2], [3, 5]).intersectsRowRange( 4,  2)).toBe true
      expect(Range([1, 2], [3, 5]).intersectsRowRange( 0,  2)).toBe true
      expect(Range([1, 2], [3, 5]).intersectsRowRange( 4,  6)).toBe false
      expect(Range([1, 2], [3, 5]).intersectsRowRange( 6,  4)).toBe false
      expect(Range([1, 2], [3, 5]).intersectsRowRange(-2, -4)).toBe false

  describe "::getExtent()", ->
    it "returns a point which start has to traverse to reach end", ->
      expect(Range([2, 2], [4, 5]).getExtent()).toEqual [2, 5]
      expect(Range([2, 2], [2, 5]).getExtent()).toEqual [0, 3]

  describe "::containsPoint(point)", ->
    describe "when the 'exclusive' option is true", ->
      it "returns true if the given point is strictly between the range's endpoints", ->
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 1], true)).toBe false
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 2], true)).toBe true
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 4], true)).toBe false

    describe "when the 'exclusive' option is false or missing", ->
      it "returns true if the given point is between the range's endpoints", ->
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 0])).toBe false
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 1])).toBe true
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 4])).toBe true
        expect(Range(Point(0, 1), Point(0, 4)).containsPoint([0, 5])).toBe false

  describe "::containsRange(otherRange)", ->
    describe "when the 'exclusive' option is true", ->
      it "returns true if the otherRange is strictly between the range's endpoints", ->
        expect(Range(Point(0, 1), Point(1, 4)).containsRange([[0, 1], [1, 3]], true)).toBe false
        expect(Range(Point(0, 1), Point(1, 4)).containsRange([[0, 2], [1, 3]], true)).toBe true
        expect(Range(Point(0, 1), Point(1, 4)).containsRange([[1, 4], [1, 9]], true)).toBe false

    describe "when the 'exclusive' option is false or missing", ->
      it "returns true if the otherRange is between the range's endpoints", ->
        expect(Range(Point(0, 1), Point(1, 4)).containsRange([[0, 0], [1, 2]])).toBe false
        expect(Range(Point(0, 1), Point(1, 4)).containsRange([[0, 1], [1, 4]])).toBe true
        expect(Range(Point(0, 1), Point(1, 4)).containsRange([[1, 4], [1, 4]])).toBe true
        expect(Range(Point(0, 1), Point(1, 4)).containsRange([[0, 5], [1, 6]])).toBe false

  describe "::deserialize(array)", ->
    it "coverts the result of Range.serialize back to a range", ->
      expect(Range.deserialize([[1, 2], [3, 4]])).toEqual [[1, 2], [3, 4]]
      expect(Range.deserialize(Range([1, 2], [3, 4]).serialize())).toEqual [[1, 2], [3, 4]]

  describe "::serialize()", ->
    it "converts the range into range-compatible array", ->
      expect(Range([1, 3], [3, 4]).serialize()).toEqual [[1, 3], [3, 4]]
      expect(Range([1, 3], [1, 3]).serialize()).toEqual [[1, 3], [1, 3]]

  describe "::toString()", ->
    it "returns the string representation of range", ->
      expect(Range([1, 3], [3, 4]).toString()).toBe "((1, 3), (3, 4))"
      expect(Range([4, 3], [2, 4]).toString()).toBe "((4, 3), (2, 4))"
      expect(Range([0, 0], [0, 0]).toString()).toBe "((0, 0), (0, 0))"
