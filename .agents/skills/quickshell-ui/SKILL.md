---
name: quickshell-ui
description: Design and implement polished Quickshell/QML UI. Use ONLY when the task is primarily visual design work: establishing or reworking a visual language, spacing/tokens, typography, coherent animation systems, or full component redesigns. Do NOT trigger for routine widget edits, layout fixes, or bug fixes that reuse the existing visual system.
license: MIT
compatibility: opencode
metadata:
  source: programmersd21/the_quickshell_book
  category: quickshell-ui
---

# Quickshell UI

Use this skill when the task is primarily visual or interaction-design work in QML/Quickshell.

## Read references selectively

- Visual system, spacing, surfaces, typography: `references/design-system.md`
- Animation and transitions: `references/motion.md`

## First inspect the existing visual language

Before redesigning a component, inspect nearby components and shared theme values for:

- palette;
- typography;
- spacing scale;
- corner radii;
- border widths;
- icon family and sizing;
- opacity hierarchy;
- motion durations/easing;
- hover/pressed/selected states.

Reuse the existing system unless the user asks to replace it.

## UI principles

- Build hierarchy with spacing, typography, contrast, and grouping before adding decoration.
- Use a small consistent spacing scale instead of one-off pixel values everywhere.
- Use shared color and radius tokens.
- Prefer a restrained number of surface levels.
- Keep interactive hit targets larger than the icon glyph itself.
- Add explicit hover, pressed, selected, disabled, and focus states when relevant.
- Use icons consistently from the project's chosen icon set.
- Avoid decorative blur/shadows when they reduce readability or cost too much to render.
- Check clipping when rounded children animate or overflow.

## Motion principles

- Motion should explain state change, not merely add movement.
- Use shared durations and easing curves.
- Entrances may be slightly slower than exits, but keep the system consistent.
- Prefer animating `opacity`, `scale`, `x`, `y`, and other cheap visual properties over repeatedly forcing layout recalculation.
- Avoid large simultaneous animations across many heavy delegates.
- Respect any reduced-motion configuration the project exposes.

## Interaction implementation

When implementing a component:

1. Establish layout and hierarchy first.
2. Add hover/pressed/selected states.
3. Add concise motion only after static states are correct.
4. Verify text truncation and unusual content lengths.
5. Verify small and large monitor scales if the project supports them.
6. Verify focus/keyboard behavior for launchers, menus, search, and controls.

## Avoid

- random per-component animation timings;
- magic colors outside the theme without a reason;
- multiple icon families in one surface;
- nested translucent surfaces with no visual hierarchy;
- tiny icon-only click areas;
- animating anchor margins/layout structure on every frame when a visual transform can communicate the same motion.
