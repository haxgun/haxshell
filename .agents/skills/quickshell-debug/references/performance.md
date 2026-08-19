# Performance guidance

## Idle CPU

First inspect:

- repeating timers;
- process spawning;
- polling services;
- frequently changing top-level properties that invalidate many bindings.

Convert polling to signals/events where possible.

## Binding cost

Move expensive repeated work out of hot bindings. Cache meaningful intermediate values when their dependencies change less often than consumers redraw.

Do not add cache state without clear invalidation.

## Layout cost

Animating layout margins, dimensions, or anchor relationships may trigger repeated layout work. When the visual result is equivalent, prefer transforms/translation/opacity/scale.

## Delegates

For ListView/GridView/Repeater-style UI:

- keep delegate trees small;
- lazy-load secondary detail;
- size images for their displayed size;
- avoid recreating the whole model on every filter/state change when a stable model mechanism is available;
- avoid invisible heavy children that remain instantiated for every row.

## Memory

Look for:

- loaders that never unload;
- retained models or JavaScript arrays that grow indefinitely;
- signal connections keeping objects alive unexpectedly;
- large images/caches;
- popup content instantiated permanently despite rare use.

## Measurement

Use Qt/QML profiling tools supported by the environment when basic inspection is insufficient. Compare before and after the optimization rather than assuming success from code appearance.
