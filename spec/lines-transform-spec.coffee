{Newline} = require "../src/symbols"
Point = require "../src/point"
LinesTransform = require "../src/lines-transform"
CharactersLayer = require "../src/characters-layer"
Layer = require "../src/layer"

describe "LinesTransform", ->
  layer = null

  beforeEach ->
    layer = new Layer(new LinesTransform, new CharactersLayer("\nabc\ndefg\n"))

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

  describe "layer", ->
    describe ".getLines()", ->
      it "returns the content as an array of lines", ->
        charactersLayer = new CharactersLayer("\nabc\ndefg\n")
        layer = new Layer(new LinesTransform, charactersLayer)

        expect(layer.getLines()).toEqual [
          "\n"
          "abc\n"
          "defg\n"
          ""
        ]

    describe ".slice(start, end)", ->
      it "returns the content between the start and end points", ->
        charactersLayer = new CharactersLayer("\nabc\ndefg\n")
        layer = new Layer(new LinesTransform, charactersLayer)

        expect(layer.slice(Point(0, 0), Point(1, 0))).toBe "\n"
        expect(layer.slice(Point(1, 0), Point(2, 0))).toBe "abc\n"
