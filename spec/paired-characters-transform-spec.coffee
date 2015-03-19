Point = require "../src/point"
PairedCharactersTransform = require "../src/paired-characters-transform"
StringLayer = require "../src/string-layer"
TransformLayer = require "../src/transform-layer"

describe "PairedCharactersTransform", ->
  layer = null

  beforeEach ->
    layer = new TransformLayer(
      new StringLayer("a\uD835\uDF97b\uD835\uDF97c"),
      new PairedCharactersTransform
    )

  it "replaces paired characters with single characters", ->
    iterator = layer[Symbol.iterator]()

    expect(iterator.next()).toEqual(value: "a", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 1))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 1))

    expect(iterator.next()).toEqual(value: "\uD835\uDF97", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 2))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 3))

    expect(iterator.next()).toEqual(value: "b", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 3))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 4))

    expect(iterator.next()).toEqual(value: "\uD835\uDF97", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 4))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 6))

    expect(iterator.next()).toEqual(value: "c", done: false)
    expect(iterator.getPosition()).toEqual(Point(0, 5))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 7))

    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.getPosition()).toEqual(Point(0, 5))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 7))
