fs = require "fs"
temp = require "temp"
FileLayer = require "../src/file-layer"

describe "FileLayer", ->
  [layer, filePath] = []

  beforeEach ->
    filePath = temp.openSync("file-layer-spec-").path
    layer = new FileLayer(filePath, 3)

  afterEach ->
    layer.destroy()

  describe "iteration", ->
    describe "::next()", ->
      it "reads the file in chunks of the given size", ->
        # α-β-γ-δ
        fs.writeFileSync(filePath, "\u03B1-\u03B2-\u03B3-\u03B4")

        iterator = layer[Symbol.iterator]()
        expect(iterator.getPosition()).toBe 0

        expect(iterator.next()).toEqual(value: "\u03B1-\u03B2", done: false)
        expect(iterator.getPosition()).toBe 3

        expect(iterator.next()).toEqual(value: "-\u03B3-", done: false)
        expect(iterator.getPosition()).toBe 6

        expect(iterator.next()).toEqual(value: "\u03B4", done: false)
        expect(iterator.getPosition()).toBe 7

        expect(iterator.next()).toEqual(done: true)
        expect(iterator.next()).toEqual(done: true)
        expect(iterator.getPosition()).toBe 7

    describe "::seek(characterIndex)", ->
      it "moves to the correct offset in the file", ->
        # α-β-γ-δ
        fs.writeFileSync(filePath, "\u03B1-\u03B2-\u03B3-\u03B4")

        iterator = layer[Symbol.iterator]()
        iterator.seek(2)
        expect(iterator.next()).toEqual(value: "\u03B2-\u03B3", done: false)
        expect(iterator.getPosition()).toBe 5

        expect(iterator.next()).toEqual(value: "-\u03B4", done: false)
        expect(iterator.getPosition()).toBe 7

        expect(iterator.next()).toEqual(done: true)
        expect(iterator.getPosition()).toBe 7
