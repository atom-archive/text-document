{EOF, Newline} = require "../src/symbols"
Point = require "../src/point"
LinesTransform = require "../src/lines-transform"
TransformIterator = require "../src/transform-iterator"
CharactersIterator = require "../src/characters-iterator"

describe "LinesTransform", ->
  it "breaks the source text into lines", ->
    linesIterator = new TransformIterator(new LinesTransform, new CharactersIterator("\nabc\ndefg\n"))
    expect(linesIterator.read()).toBe(Newline)
    expect(linesIterator.getPosition()).toEqual(Point(1, 0))
    expect(linesIterator.getSourcePosition()).toEqual(Point(0, 1))

    expect(linesIterator.read()).toBe("abc")
    expect(linesIterator.getPosition()).toEqual(Point(1, 3))
    expect(linesIterator.getSourcePosition()).toEqual(Point(0, 4))

    expect(linesIterator.read()).toBe(Newline)
    expect(linesIterator.getPosition()).toEqual(Point(2, 0))
    expect(linesIterator.getSourcePosition()).toEqual(Point(0, 5))

    expect(linesIterator.read()).toBe("defg")
    expect(linesIterator.getPosition()).toEqual(Point(2, 4))
    expect(linesIterator.getSourcePosition()).toEqual(Point(0, 9))

    expect(linesIterator.read()).toBe(Newline)
    expect(linesIterator.getPosition()).toEqual(Point(3, 0))
    expect(linesIterator.getSourcePosition()).toEqual(Point(0, 10))

    expect(linesIterator.read()).toBe(EOF)
    expect(linesIterator.read()).toBe(EOF)
    expect(linesIterator.getPosition()).toEqual(Point(3, 0))
    expect(linesIterator.getSourcePosition()).toEqual(Point(0, 10))
