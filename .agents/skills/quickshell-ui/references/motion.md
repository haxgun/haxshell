# Motion guidance

Create shared motion tokens instead of inventing timings inside every component.

Typical categories:

- instant feedback;
- fast state change;
- normal movement;
- expand/collapse;
- modal/popup entrance.

The exact values should come from the project's design system.

## Prefer

- opacity fade for appearance/disappearance;
- small scale changes for pressed/selected feedback;
- translation for sliding surfaces;
- color interpolation for state changes;
- a consistent easing family.

## Avoid

- bounce effects on routine interactions unless they are part of the requested style;
- long exit animations that make UI feel unresponsive;
- animating geometry that causes expensive full layout work when a transform is sufficient;
- staggered animations on large lists unless performance has been considered.

## Validation

Check the component at the beginning, middle, and end of its transition. Verify that click handling and visibility do not become inconsistent during the animation.
