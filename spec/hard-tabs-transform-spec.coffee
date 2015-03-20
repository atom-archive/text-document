Point = require "../src/point"
HardTabsTransform = require "../src/hard-tabs-transform"
StringLayer = require "../src/string-layer"
TransformLayer = require "../src/transform-layer"

describe "HardTabsTransform", ->
  [stringLayer, hardTabsLayer] = []

  beforeEach ->
    stringLayer = new StringLayer("\tabc\tdefg\t")
    hardTabsLayer = new TransformLayer(stringLayer, new HardTabsTransform(4))

  it "expands hard tab characters to spaces based on the given tab length", ->
    iterator = hardTabsLayer[Symbol.iterator]()
    expect(iterator.next()).toEqual(value: "\t   ", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 4))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 1))

    expect(iterator.next()).toEqual(value: "abc", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 7))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 4))

    expect(iterator.next()).toEqual(value: "\t", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 8))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 5))

    expect(iterator.next()).toEqual(value: "defg", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 12))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 9))

    expect(iterator.next()).toEqual(value: "\t   ", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 16))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 10))

    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.getPosition()).toEqual(Point(0, 16))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 10))

  it "correctly translates positions", ->
    expectMappings(hardTabsLayer, stringLayer, [
      [Point(0, 0), Point(0, 0)]
      [Point(0, 4), Point(0, 1)]
      [Point(0, 5), Point(0, 2)]
      [Point(0, 12), Point(0, 9)]
      [Point(0, 16), Point(0, 10)]
    ])
