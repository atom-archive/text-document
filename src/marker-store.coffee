{Emitter} = require "event-kit"
Point = require "./point"
Range = require "./range"
Marker = require "./marker"
MarkerIndex = require "./marker-index"

module.exports =
class MarkerStore
  constructor: ->
    @index = new MarkerIndex
    @emitter = new Emitter
    @markersById = {}
    @nextMarkerId = 0

  ###
  Section: TextDocument API
  ###

  getMarker: (id) ->
    @markersById[id]

  getMarkers: ->
    marker for id, marker of @markersById

  findMarkers: (params) ->
    markerIds = new Set(Object.keys(@markersById))

    if params.startPosition?
      point = Point.fromObject(params.startPosition)
      intersectSet(markerIds, @index.findStartingAt(point))
      delete params.startPosition

    if params.endPosition?
      point = Point.fromObject(params.endPosition)
      intersectSet(markerIds, @index.findEndingAt(point))
      delete params.endPosition

    if params.containsPoint?
      point = Point.fromObject(params.containsPoint)
      intersectSet(markerIds, @index.findContaining(point))
      delete params.containsPoint

    if params.containsRange?
      {start, end} = Range.fromObject(params.containsRange)
      intersectSet(markerIds, @index.findContaining(start, end))
      delete params.containsRange

    if params.intersectsRange?
      {start, end} = Range.fromObject(params.intersectsRange)
      intersectSet(markerIds, @index.findIntersecting(start, end))
      delete params.intersectsRange

    result = []
    for id, marker of @markersById
      result.push(marker) if markerIds.has(id) and marker.matchesParams(params)
    result.sort (marker1, marker2) -> marker1.compare(marker2)

  markRange: (range, options={}) ->
    range = Range.fromObject(range)
    options.invalidate ?= 'overlap'
    marker = new Marker(String(@nextMarkerId++), this, options)
    @markersById[marker.id] = marker
    @index.insert(marker.id, range.start, range.end)
    @emitter.emit("did-create-marker", marker)
    marker

  markPosition: (position, options) ->
    @markRange(Range(position, position), options)

  onDidCreateMarker: (callback) ->
    @emitter.on("did-create-marker", callback)

  ###
  Section: Marker API
  ###

  destroyMarker: (id) ->
    delete @markersById[id]
    @index.delete(id)

  getMarkerRange: (id) ->
    @index.getRange(id)

  getMarkerStartPosition: (id) ->
    @index.getStart(id)

  getMarkerEndPosition: (id) ->
    @index.getEnd(id)

intersectSet = (set, other) ->
  set.forEach (value) -> set.delete(value) unless other.has(value)
