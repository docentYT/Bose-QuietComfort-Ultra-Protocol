
/**
 * Create a family of counters with one parent and many children under one id.
 * 
 * This allows us to create arbitrarily many unique counters without
 * requiring unique strings for each one.
 * 
 * Args:
 * - id: str. The unique id for this counter family.
 * 
 * Returns two functions:
 * - The parent's step function (to be placed as content exactly once).
 *   - Does not need context to call.
 * - A function for getting the current child of the parent.
 *   - May only be called with context
 * 
 * Example:
 * ```typ
 * #let (parent-step, get-child) = counter-family("some string")
 * Place the parent step once per call:
 * #parent-step()
 * Then get the child in context and step it when you want:
 * #context { let child = get-child(); child.step() }
 * ```
 * 
 * Note: I do not believe that this works correctly when parents are nested within
 * children. Not sure what a solution to that would look like.
 */
#let counter-family(id) = {
  let parent = counter(id)
  let parent-step() = parent.step()
  let get-child() = counter(id + str(parent.get().at(0)))
  return (parent-step, get-child)
}

// A fun zig-zag line!
#let zig-zag(fill: black, rough-width: 6pt, height: 4pt, thick: 1pt, angle: 0deg) = {
  layout((size) => {
    // Use layout to get the size and measure our horizontal distance
    // Then get the per-zigzag width with some maths.
    let count = int(calc.round(size.width / rough-width))
    // Need to add extra thickness since we join with `h(-thick)`
    let width = thick + (size.width - thick) / count
    // One zig and one zag:
    let zig-and-zag = {
      let line-stroke = stroke(thickness: thick, cap: "round", paint: fill)
      let top-left = (thick/2, thick/2)
      let bottom-mid = (width/2, height - thick/2)
      let top-right = (width - thick/2, thick/2)
      let zig = line(stroke: line-stroke, start: top-left, end: bottom-mid)
      let zag = line(stroke: line-stroke, start: bottom-mid, end: top-right)
      box(place(zig) + place(zag), width: width, height: height, clip: true)
    }
    let zig-zags = ((zig-and-zag,) * count).join(h(-thick))
    rotate(zig-zags, angle)
  })
}
