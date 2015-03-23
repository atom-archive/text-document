Point = require "../src/point"
LinesTransform = require "../src/lines-transform"
StringLayer = require "../src/string-layer"
TransformLayer = require "../src/transform-layer"

describe "LinesTransform", ->
  layer = null

  beforeEach ->
    layer = new TransformLayer(new StringLayer("\nabc\r\ndefg\n"), new LinesTransform)

  it "breaks the source text into lines", ->
    iterator = layer.buildIterator()
    expect(iterator.next()).toEqual(value: "\n", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 1))

    expect(iterator.next()).toEqual(value: "abc", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 3))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 4))

    expect(iterator.next()).toEqual(value: "\n", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 6))

    expect(iterator.next()).toEqual(value: "defg", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 4))

    expect(iterator.next()).toEqual(value: "\n", done: false)
    expect(iterator.getPosition()).toEqual(Point(3, 0))

    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.getPosition()).toEqual(Point(3, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 11))

  it "maps target positions to source positions and vice-versa", ->
    expectMapsSymmetrically(layer, Point(0, 0), Point(0, 0))
    expectMapsSymmetrically(layer, Point(0, 1), Point(1, 0))
    expectMapsSymmetrically(layer, Point(0, 2), Point(1, 1))
    expectMapsSymmetrically(layer, Point(0, 3), Point(1, 2))
    expectMapsSymmetrically(layer, Point(0, 6), Point(2, 0))
