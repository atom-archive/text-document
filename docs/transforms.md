# Transforms

Transforms are programmatically defined patches. A patch is a set of explicit instructions for translating a specific input stream to a specific output stream, a *transform* is basically a program that *computes* a patch based on the input stream.

## Transform Functions

Transforms are defined by functions that are invoked repeatedly to return one or more hunks based on the input stream at a specific location. A transform functions has access to the start location in the input and the output for the hunks it is being called to compute. A transform function can also read content from the input stream.

### Transform Function Parameters:

* `inputPosition` – A `Point`
* `outputPosition` – A `Point`
* `read` – A function that returns the next chunk of content from the input.

The function returns one or more *hunks*, plain objects with an `inputExtent`, an `outputExtent`, and a `content` field. The `content` field can contain either explicit content or a `Point` representing an extent in the input for which the output is identical. We call hunks returned from the same invocation of the transform function *sibling hunks*.

### Transform Function Return Value

* An `Array` of objects with the following keys:
  * `inputExtent`
  * `outputExtent`
  * `content`

## Hunk Invalidation

The output of a transform is a function of the input. When the input changes, we update the patch to reflect the result of applying the transform to the newest input.

First, we update the existing patch by splicing the new range into the old range in the input dimension. Then we determine which hunks were invalidated and need to be recomputed. Hunks are invalidated if they intersect the old range or have a sibling that does.

Starting at the start of the first invalidated hunk, the transform function is reinvoked until enough hunks are returned to fill in the invalidated range. Because we always invalidate siblings, we essentially "replay" one or more transform invocations with new input.

If a given transform requires buffering of earlier input to make decisions later, this dependency is captured by always restarting at the first sibling of the hunk intersecting the change. So long as the transform function consults no other state but what is available to it via its parameters, we can invalidate hunks that don't themselves intersect the change, but depend in some way on the changed content.

For example, the soft wraps transform can always buffer the entirety of any line it is soft-wrapping. This means that changes on any segment of the line invalidate the entire line, allowing us to re-wrap the line. Finer grained invalidation may be possible, but we may be able to afford rewrapping everything if the soft wrap transform function is efficient.

## Ad-Hoc State Propagation

Another potential invalidation tool is ad-hoc state propagation, in which a given invocation of the transform function can return an immutable state object that is passed to the next invocation of the transform function. We associate this state with each run of sibling regions, and whenever they are invalidated we cascade the invalidation to the next run of siblings if the state has changed in the new invocation.

This generalizes our current approach to resuming the parser. For each invocation of the parser transform, we return the parser's stack state. If a change occurs that causes the state of the parser to be different at the end of a chunk of content, we'll invalidate the subsequent region and continue parsing. This can occur for example when inserting a quote momentarily switches all non-strings in the document to strings and vice versa.

## Cascaded Invalidations

A more sophisticated possible approach could augment grouped sibling invalidation. When a hunk gets invalidated, we could expect the next hunk to exactly fill the invalidated window. If it didn't, we would invalidate the next hunk too and invoke the transform function again at the end of the last new hunk, repeating the process recursively.

This could potentially save work in situations like soft wrap, because so long as the input change didn't cause a change in the wrapping structure, only a single line segment would be invalidated. We would also only invalidate line segments following the edited segment.

Because soft-wrap is indentation aware, the indentation level of the line would need to be passed via ad-hoc state propagation for this approach to be viable.  
