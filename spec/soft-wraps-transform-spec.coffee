Point = require "../src/point"
SoftWrapsTransform = require "../src/soft-wraps-transform"
StringLayer = require "../spec/string-layer"
TransformLayer = require "../src/transform-layer"

{expectMapsSymmetrically} = require "./spec-helper"

describe "SoftWrapsTransform", ->
  it "inserts a line-break at the end of the last whitespace sequence that starts before the max column", ->
    layer = new TransformLayer(
      new StringLayer("abc def ghi jklmno\tpqr"),
      new SoftWrapsTransform(10)
    )

    iterator = layer.buildIterator()
    expect(iterator.next()).toEqual(value: "abc def ", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 8))

    expect(iterator.next()).toEqual(value: "ghi jklmno\t", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 19))

    expect(iterator.next()).toEqual(value: "pqr", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 3))
    expect(iterator.getInputPosition()).toEqual(Point(0, 22))

    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.getPosition()).toEqual(Point(2, 3))
    expect(iterator.getInputPosition()).toEqual(Point(0, 22))

    iterator.seek(Point(0, 4))
    expect(iterator.getInputPosition()).toEqual(Point(0, 4))

    expect(iterator.next()).toEqual(value: "def ", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 8))

  it "breaks lines within words if there is no whitespace starting before the max column", ->
    layer = new TransformLayer(
      new StringLayer("abcdefghijkl"),
      new SoftWrapsTransform(5)
    )

    iterator = layer.buildIterator()
    expect(iterator.next()).toEqual(value: "abcde", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 5))

    expect(iterator.next()).toEqual(value: "fghij", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 10))

    expect(iterator.next()).toEqual(value: "kl", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 2))
    expect(iterator.getInputPosition()).toEqual(Point(0, 12))

    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.getPosition()).toEqual(Point(2, 2))
    expect(iterator.getInputPosition()).toEqual(Point(0, 12))

  it "reads from the input layer until it reads a newline or it exceeds the max column", ->
    layer = new TransformLayer(
      new StringLayer("abc defghijkl", 5),
      new SoftWrapsTransform(10)
    )

    iterator = layer.buildIterator()
    expect(iterator.next()).toEqual(value: "abc ", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 4))

    expect(iterator.next()).toEqual(value: "defghijkl", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 9))
    expect(iterator.getInputPosition()).toEqual(Point(0, 13))

  it "maps target positions to input positions and vice-versa", ->
    layer = new TransformLayer(
      new StringLayer("abcdefghijkl"),
      new SoftWrapsTransform(5)
    )

    expectMapsSymmetrically(layer, Point(0, 0), Point(0, 0))
    expectMapsSymmetrically(layer, Point(0, 1), Point(0, 1))
    expectMapsSymmetrically(layer, Point(0, 5), Point(1, 0))
    expectMapsSymmetrically(layer, Point(0, 6), Point(1, 1))
    expectMapsSymmetrically(layer, Point(0, 10), Point(2, 0))

  it "soft warp Japanese text with latin characters", ->
    layer = new TransformLayer(
      new StringLayer("君達のパッケージは、全てGitHubがいただいた。"),
      new SoftWrapsTransform(6, true)
    )

    iterator = layer.buildIterator()
    expect(iterator.next()).toEqual(value: "君達の", done: false)
    expect(iterator.getPosition()).toEqual(Point(1, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 3))

    expect(iterator.next()).toEqual(value: "パッケ", done: false)
    expect(iterator.getPosition()).toEqual(Point(2, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 6))

    # not allow to break before "、", so move "は" to the next line
    expect(iterator.next()).toEqual(value: "ージ", done: false)
    expect(iterator.getPosition()).toEqual(Point(3, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 8))

    expect(iterator.next()).toEqual(value: "は、全", done: false)
    expect(iterator.getPosition()).toEqual(Point(4, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 11))

    # not allow to break "GitHub", so move "GitHub" to the next line
    expect(iterator.next()).toEqual(value: "て", done: false)
    expect(iterator.getPosition()).toEqual(Point(5, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 12))

    expect(iterator.next()).toEqual(value: "GitHub", done: false)
    expect(iterator.getPosition()).toEqual(Point(6, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 18))

    expect(iterator.next()).toEqual(value: "がいた", done: false)
    expect(iterator.getPosition()).toEqual(Point(7, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 21))

    # not allow to break before "。", so move "た" to the next line
    expect(iterator.next()).toEqual(value: "だい", done: false)
    expect(iterator.getPosition()).toEqual(Point(8, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 23))

    expect(iterator.next()).toEqual(value: "た。", done: false)
    expect(iterator.getPosition()).toEqual(Point(9, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 25))

    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.next()).toEqual {value: undefined, done: true}
    expect(iterator.getPosition()).toEqual(Point(9, 0))
    expect(iterator.getInputPosition()).toEqual(Point(0, 25))
