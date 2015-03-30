Point = require "./point"
Range = require "./range"

BRANCHING_FACTOR = 3

class Node
  constructor: (@children) ->
    @extent = Point.zero()
    for child in @children
      @extent = @extent.traverse(child.extent)

  insert: (id, start, end) ->
    # Insert the given id into all children that intersect the given range.
    # Take the intersection of the given range and the child's range when
    # inserting into each child.
    rangeIsEmpty = start.compare(end) is 0
    childStart = Point.zero()
    i = 0
    while i < @children.length
      child = @children[i]
      childEnd = childStart.traverse(child.extent)
      if rangeIsEmpty
        childIntersectsRange = childEnd.compare(start) >= 0
      else
        childIntersectsRange = childEnd.compare(start) > 0

      if childIntersectsRange
        intersectionStart = Point.max(start, childStart)
        intersectionEnd = Point.min(end, childEnd)
        if newChildren = child.insert(id, intersectionStart.traversalFrom(childStart), intersectionEnd.traversalFrom(childStart))
          @children.splice(i, 1, newChildren...)
          i += newChildren.length
        else
          i++
      else
        i++

      break if childEnd.compare(end) >= 0

      childStart = childEnd

    if @children.length > BRANCHING_FACTOR
      splitIndex = Math.ceil(@children.length / BRANCHING_FACTOR)
      [new Node(@children.slice(0, splitIndex)), new Node(@children.slice(splitIndex))]

  getStart: (id) ->
    childStart = Point.zero()
    for child in @children
      if startRelativeToChild = child.getStart(id)
        return childStart.traverse(startRelativeToChild)
      childStart = childStart.traverse(child.extent)
    return

  getEnd: (id) ->
    childStart = Point.zero()
    for child in @children
      if endRelativeToChild = child.getEnd(id)
        end = childStart.traverse(endRelativeToChild)
      else if end?
        break
      childStart = childStart.traverse(child.extent)
    end

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

  toString: (indentLevel=0) ->
    indent = ""
    indent += " " for i in [0...indentLevel] by 1

    """
      #{indent}Node #{@extent}
      #{@children.map((c) -> c.toString(indentLevel + 2)).join("\n")}
    """

class Leaf
  constructor: (@extent, @ids) ->

  insert: (id, start, end) ->
    # If the given range matches the start and end of this leaf exactly, add
    # the given id to this leaf. Otherwise, split this leaf into up to 3 leaves,
    # adding the id to the portion of this leaf that intersects the given range.
    if start.isZero() and end.compare(@extent) is 0
      @ids.add(id)
      return
    else
      newIds = new Set(@ids)
      newIds.add(id)
      newLeaves = []
      newLeaves.push(new Leaf(start, new Set(@ids))) if start.isPositive()
      newLeaves.push(new Leaf(end.traversalFrom(start), newIds))
      newLeaves.push(new Leaf(@extent.traversalFrom(end), new Set(@ids))) if @extent.compare(end) > 0
      newLeaves

  getStart: (id) ->
    Point.zero() if @ids.has(id)

  getEnd: (id) ->
    @extent if @ids.has(id)

  findContaining: (start, end) -> @ids

  toString: (indentLevel=0) ->
    indent = ""
    indent += " " for i in [0...indentLevel] by 1

    ids = []
    values = @ids.values()
    until (next = values.next()).done
      ids.push(next.value)

    "#{indent}Leaf #{@extent} (#{ids.join(" ")})"

module.exports =
class MarkerIndex
  constructor: ->
    @rootNode = new Leaf(Point.infinity(), new Set)

  insert: (id, start, end) ->
    if splitNodes = @rootNode.insert(id, start, end)
      @rootNode = new Node(splitNodes)

  getRange: (id) ->
    Range(@getStart(id), @getEnd(id))

  getStart: (id) ->
    @rootNode.getStart(id)

  getEnd: (id) ->
    @rootNode.getEnd(id)

  findContaining: (start, end=start) ->
    new Set(@rootNode.findContaining(start, end))

setIntersection = (a, b) ->
  intersection = new Set
  a.forEach (item) -> intersection.add(item) if b.has(item)
  intersection

setUnion = (a, b) ->
  union = new Set
  a.forEach (item) -> union.add(item)
  b.forEach (item) -> union.add(item)
  union
