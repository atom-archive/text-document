Point = require "./point"

class Node
  constructor: (@children) ->
    @extent = Point.zero()
    for child in @children
      @extent = @extent.traverse(child.extent)

  insert: (id, start, end) ->
    # Insert the given id into all children that intersect the given range.
    # Take the intersection of the given range and the child's range when
    # inserting into each child.
    childStart = Point.zero()
    i = 0
    while i < @children.length
      break if childStart.compare(end) > 0

      child = @children[i]
      childEnd = childStart.traverse(child.extent)

      if childEnd.compare(start) > 0
        intersectionStart = Point.max(start, childStart)
        intersectionEnd = Point.min(end, childEnd)
        if newChildren = child.insert(id, intersectionStart.traversalFrom(childStart), intersectionEnd.traversalFrom(childStart))
          @children.splice(i, 1, newChildren...)
          i += newChildren.length
        else
          i++
      else
        i++

      childStart = childEnd
    return

  findContaining: (start, end) ->
    # We break this query into subqueries on our children. For any child that
    # intersects the query range, we ask the child for markers containing the
    # subset of the query range covered by that child.
    #
    # The search is slightly different depending on whether the search range
    # is empty or not. If the range is empty, we need to query children that
    # start or end at the point we're searching for and take the union of
    # the subquery results. Otherwise, we stop searching earlier, at the first
    # child that contains the end of our search range and take the intersection
    # of the subquery results.
    containingIds = null
    searchRangeEmpty = start.compare(end) is 0

    childStart = Point.zero()
    for child in @children
      if searchRangeEmpty
        break if childStart.compare(end) > 0
      else
        break if childStart.compare(end) >= 0

      childEnd = childStart.traverse(child.extent)

      if childEnd.compare(start) > 0 or childEnd.compare(end) >= 0
        intersectionStart = Point.max(start, childStart)
        intersectionEnd = Point.min(end, childEnd)
        childContainingIds = child.findContaining(intersectionStart.traversalFrom(childStart), intersectionEnd.traversalFrom(childStart))
        if containingIds?
          if searchRangeEmpty
            containingIds = setUnion(containingIds, childContainingIds)
          else
            containingIds = setIntersection(containingIds, childContainingIds)
        else
          containingIds = childContainingIds

      childStart = childEnd

    containingIds

  toString: ->
    "<Node #{@extent} [#{@children.join(" ")}]>"

class Leaf
  constructor: (@extent, @ids) ->

  insert: (id, start, end) ->
    # If the given range matches the start and end of this leaf exactly, add
    # the given id to this leaf. Otherwise, split this leaf into up to 3 leaves,
    # adding the id to the portion of this leaf that intersects the given range.
    if start.isZero() and end.compare(@extent) is 0
      @ids.add(id)
      this
    else
      newIds = new Set(@ids)
      newIds.add(id)
      newLeaves = []
      newLeaves.push(new Leaf(start, new Set(@ids))) if start.isPositive()
      newLeaves.push(new Leaf(end.traversalFrom(start), newIds))
      newLeaves.push(new Leaf(@extent.traversalFrom(end), new Set(@ids))) if @extent.compare(end) > 0
      newLeaves

  findContaining: (start, end) -> @ids

  toString: ->
    ids = []
    values = @ids.values()
    until (next = values.next()).done
      ids.push(next.value)
    "<Leaf #{@extent} (#{ids.join(" ")})>"

module.exports =
class MarkerIndex
  constructor: ->
    @rootNode = new Leaf(Point.infinity(), new Set)

  insert: (id, start, end) ->
    if splitNodes = @rootNode.insert(id, start, end)
      @rootNode = new Node(splitNodes)

  findContaining: (start, end=start) ->
    @rootNode.findContaining(start, end)

setIntersection = (a, b) ->
  intersection = new Set
  a.forEach (item) -> intersection.add(item) if b.has(item)
  intersection

setUnion = (a, b) ->
  union = new Set
  a.forEach (item) -> union.add(item)
  b.forEach (item) -> union.add(item)
  union
