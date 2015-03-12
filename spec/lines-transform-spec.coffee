Point = require "../src/point"
{Newline} = require "../src/symbols"
LinesTransform = require "../src/lines-transform"
StringLayer = require "../src/string-layer"
TransformLayer = require "../src/transform-layer"

describe "LinesTransform", ->
  layer = null

  beforeEach ->
    layer = new TransformLayer(new LinesTransform, new StringLayer("\nabc\ndefg\n"))

  it "breaks the source text into lines", ->
    iterator = layer[Symbol.iterator]()
    expect(iterator.next()).toEqual(value: "\n", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 1))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 1))

    expect(iterator.next()).toEqual(value: Newline, done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 1))

    expect(iterator.next()).toEqual(value: "abc\n", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 4))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 5))

    expect(iterator.next()).toEqual(value: Newline, done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 5))

    expect(iterator.next()).toEqual(value: "defg\n", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 5))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 10))

    expect(iterator.next()).toEqual(value: Newline, done: false)
    expect(iterator.getPosition()).toEqual(Point(3, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 10))

    expect(iterator.next()).toEqual(done: true)
    expect(iterator.next()).toEqual(done: true)
    expect(iterator.getPosition()).toEqual(Point(3, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 10))
