Point = require "../src/point"
SoftWrapsTransform = require "../src/soft-wraps-transform"
StringLayer = require "../src/string-layer"
SpyLayer = require "./spy-layer"
TransformLayer = require "../src/transform-layer"

describe "SoftWrapsTransform", ->
  it "breaks each line at the last word boundary before the per-line character limit", ->
    layer = new TransformLayer(
      new StringLayer("abc def ghi jklmno\tpqr"),
      new SoftWrapsTransform(10)
    )

    iterator = layer[Symbol.iterator]()
    expect(iterator.next()).toEqual(value: "abc def ", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 8))

    expect(iterator.next()).toEqual(value: "ghi jklmno\t", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 19))

    expect(iterator.next()).toEqual(value: "pqr", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 3))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 22))

    expect(iterator.next()).toEqual(done: true)
    expect(iterator.next()).toEqual(done: true)
    expect(iterator.getPosition()).toEqual(Point(2, 3))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 22))

    iterator.seek(Point(0, 4))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 4))

    expect(iterator.next()).toEqual(value: "def ", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 8))

  it "breaks each line at the last word boundary before the per-line character limit", ->
    layer = new TransformLayer(
      new StringLayer("abcdefghijkl"),
      new SoftWrapsTransform(5)
    )

    iterator = layer[Symbol.iterator]()
    expect(iterator.next()).toEqual(value: "abcde", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 5))

    expect(iterator.next()).toEqual(value: "fghij", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 0))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 10))

    expect(iterator.next()).toEqual(value: "kl", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 2))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 12))

    expect(iterator.next()).toEqual(done: true)
    expect(iterator.next()).toEqual(done: true)
    expect(iterator.getPosition()).toEqual(Point(2, 2))
    expect(iterator.getSourcePosition()).toEqual(Point(0, 12))
