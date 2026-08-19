---
name: quickshell-debug
description: Diagnose and optimize Quickshell/QML shells. Use for startup failures, QML errors, broken imports, invisible popups, high CPU/RAM, stuttering animations, excessive polling, slow delegates, binding problems, and Quickshell runtime debugging.
license: MIT
compatibility: opencode
metadata:
  source: programmersd21/the_quickshell_book
  category: diagnostics
---

# Quickshell Debugging and Performance

Use this skill when something is broken, slow, unstable, or consuming too many resources.

Read:

- `references/debugging.md` for correctness/runtime failures;
- `references/performance.md` for CPU, memory, latency, and animation issues.

## Debugging order

Do not start by rewriting the component.

1. Reproduce the problem.
2. Capture the terminal/runtime error.
3. Identify the smallest failing component or service.
4. Check imports, types, bindings, and lifecycle.
5. Check whether the error is version/API mismatch.
6. Make one focused fix.
7. Re-run and compare.

## Performance order

Do not optimize from intuition alone when measurement is available.

1. Identify the observable symptom: CPU, memory, startup, popup latency, frame drops.
2. Inspect timers/processes first for shells with high idle CPU.
3. Inspect heavy delegates/images for UI jank.
4. Inspect binding churn and layout-triggering animations.
5. Profile with available Qt/QML tools for deeper issues.
6. Measure after the change.

## Common high-value checks

- very short repeating `Timer` intervals;
- repeated `Process`/`hyprctl` calls;
- duplicate services doing the same work;
- large images decoded at source resolution for tiny UI;
- expensive JavaScript in frequently reevaluated bindings;
- list delegates with large hidden component trees;
- components kept alive while permanently invisible;
- animation of properties that force continuous relayout;
- accidental circular bindings;
- assignments that unexpectedly destroy property bindings.

## Editing rule

Do not hide an error by swallowing it or adding arbitrary delays unless the root cause requires asynchronous sequencing. Preserve diagnostics until the issue is understood.
