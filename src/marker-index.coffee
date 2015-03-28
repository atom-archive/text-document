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

  findContaining: (start, end) ->
    []
