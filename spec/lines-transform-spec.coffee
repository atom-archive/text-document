Point = require "../src/point"
LinesTransform = require "../src/lines-transform"
StringLayer = require "../src/string-layer"
TransformLayer = require "../src/transform-layer"

describe "LinesTransform", ->
  layer = null

  beforeEach ->
    layer = new TransformLayer(new StringLayer("\nabc\ndefg\n"), new LinesTransform)

  it "breaks the source text into lines", ->
    iterator = layer[Symbol.iterator]()
    expect(iterator.next()).toEqual(value: "\n", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 1))

    expect(iterator.next()).toEqual(value: "abc\n", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 5))

    expect(iterator.next()).toEqual(value: "defg\n", done: false)
    expect(iterator.getPosition()).toEqual(Point(3, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 10))

    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.getPosition()).toEqual(Point(3, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 10))

  it "correctly translates positions", ->
    expectMappings(layer, [
      [Point(0, 0), Point(0, 0)]
      [Point(1, 0), Point(0, 1)]
      [Point(2, 0), Point(0, 5)]
      [Point(2, 4), Point(0, 9)]
      [Point(3, 0), Point(0, 10)]
    ])
