require 'coffee-cache'

Marker = require "../src/marker"
Marker::jasmineToString = -> @toString()

currentSpecResult = null
jasmine.getEnv().addReporter specStarted: (result) -> currentSpecResult = result
currentSpecFailed = -> currentSpecResult.failedExpectations.length > 0

beforeEach -> jasmine.addCustomEqualityTester (a, b) -> a?.isEqual?(b)

expectMapsToInput = (layer, inputPosition, position, clip) ->
  expect(layer.toInputPosition(position, clip)).toEqual(inputPosition)

expectMapsFromInput = (layer, inputPosition, position, clip) ->
  expect(layer.fromInputPosition(inputPosition, clip)).toEqual(position)

expectMapsSymmetrically = (layer, inputPosition, position) ->
  expectMapsToInput(layer, inputPosition, position)
  expectMapsFromInput(layer, inputPosition, position)

getAllIteratorValues = (iterator) ->
  values = []
  until (next = iterator.next()).done
    values.push(next.value)
  values

toEqualSet = ->
  compare: (actualSet, expectedItems, customMessage) ->
    result = {pass: true, message: ""}
    expectedSet = new Set(expectedItems)

    expectedSet.forEach (item) ->
      unless actualSet.has(item)
        result.pass = false
        result.message = "Expected set #{formatSet(actualSet)} to have item #{item}."

    actualSet.forEach (item) ->
      unless expectedSet.has(item)
        result.pass = false
        result.message = "Expected set #{formatSet(actualSet)} not to have item #{item}."

    result.message += " " + customMessage if customMessage?
    result

formatSet = (set) ->
  "(#{setToArray(set).join(' ')})"

setToArray = (set) ->
  items = []
  set.forEach (item) -> items.push(item)
  items.sort()

difference = (arrayA, arrayB) ->
  diff = []
  for element in arrayA
    diff.push(element) unless element in arrayB
  diff

module.exports = {
  currentSpecFailed, expectMapsToInput, expectMapsFromInput,
  expectMapsSymmetrically, toEqualSet, getAllIteratorValues, difference
}
