Point = require "./point"
Range = require "./range"

BRANCHING_FACTOR = 3

class Node
  constructor: (@children) ->
    @ids = new Set
    @extent = Point.zero()
    for child in @children
      @extent = @extent.traverse(child.extent)
      child.ids.forEach (id) => @ids.add(id)

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
    else
      @ids.add(id)
      return

  delete: (id) ->
    if @ids.has(id)
      @ids.delete(id)
      i = 0
      while i < @children.length
        @children[i].delete(id)
        if @children[i - 1]?.shouldMergeWith(@children[i])
          @children.splice(i - 1, 2, @children[i - 1].merge(@children[i]))
        else
          i++

  shouldMergeWith: (other) ->
    @children.length + other.children.length <= BRANCHING_FACTOR

  merge: (other) ->
    new Node(@children.concat(other.children))

  getStart: (id) ->
    return unless @ids.has(id)
    childStart = Point.zero()
    for child in @children
      if startRelativeToChild = child.getStart(id)
        return childStart.traverse(startRelativeToChild)
      childStart = childStart.traverse(child.extent)
    return

  getEnd: (id) ->
    return unless @ids.has(id)
    childStart = Point.zero()
    for child in @children
      if endRelativeToChild = child.getEnd(id)
        end = childStart.traverse(endRelativeToChild)
      else if end?
        break
      childStart = childStart.traverse(child.extent)
    end

  findContaining: (point, set) ->
    childStart = Point.zero()
    for child in @children
      childEnd = childStart.traverse(child.extent)
      if point.compare(childStart) >= 0 and point.compare(childEnd) <= 0
        child.findContaining(point.traversalFrom(childStart), set)
      break if childEnd.compare(point) > 0
      childStart = childEnd

  toString: (indentLevel=0) ->
    indent = ""
    indent += " " for i in [0...indentLevel] by 1

    ids = []
    values = @ids.values()
    until (next = values.next()).done
      ids.push(next.value)

    """
      #{indent}Node #{@extent} (#{ids.join(" ")})
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

  delete: (id) ->
    @ids.delete(id)

  shouldMergeWith: (other) ->
    setEqual(@ids, other.ids)

  merge: (other) ->
    new Leaf(@extent.traverse(other.extent), new Set(@ids))

  getStart: (id) ->
    Point.zero() if @ids.has(id)

  getEnd: (id) ->
    @extent if @ids.has(id)

  findContaining: (point, set) ->
    @ids.forEach (id) -> set.add(id)

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

  delete: (id) ->
    @rootNode.delete(id)

  getRange: (id) ->
    if start = @getStart(id)
      Range(start, @getEnd(id))

  getStart: (id) ->
    @rootNode.getStart(id)

  getEnd: (id) ->
    @rootNode.getEnd(id)

  findContaining: (start, end) ->
    containing = new Set
    @rootNode.findContaining(start, containing)
    if end? and end.compare(start) isnt 0
      containingEnd = new Set
      @rootNode.findContaining(end, containingEnd)
      containing.forEach (id) -> containing.delete(id) unless containingEnd.has(id)
    containing

setEqual = (a, b) ->
  return false unless a.size is b.size
  iterator = a.values()
  until (next = iterator.next()).done
    return false unless b.has(next.value)
  true
