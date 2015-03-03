{EOF, Newline} = require "../src/symbols"
LinesTransform = require "../src/lines-transform"
TransformIterator = require "../src/transform-iterator"
CharactersIterator = require "../src/characters-iterator"

describe "LinesTransform", ->
  it "breaks the source text into lines", ->
    linesIterator = new TransformIterator(new LinesTransform, new CharactersIterator("\nabc\ndefg\n"))
    expect(linesIterator.read()).toBe(Newline)
    expect(linesIterator.read()).toBe("abc")
    expect(linesIterator.read()).toBe(Newline)
    expect(linesIterator.read()).toBe("defg")
    expect(linesIterator.read()).toBe(Newline)
    expect(linesIterator.read()).toBe(EOF)
