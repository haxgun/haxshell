---
name: quickshell-core
description: Build and refactor Quickshell shells and QML components. Use for shell.qml, project structure, PanelWindow/FloatingWindow/PopupWindow, reusable components, services, state, imports, multi-monitor behavior, and general Quickshell implementation work.
license: MIT
compatibility: opencode
metadata:
  source: programmersd21/the_quickshell_book
  category: quickshell-core
---

# Quickshell Core

Use this skill for general Quickshell implementation and architecture work.

## Source of truth

The reference material in this skill distills practices from `programmersd21/the_quickshell_book`, but Quickshell evolves quickly.

Before introducing or changing a Quickshell-specific type, property, signal, method, enum, or module import:

1. Inspect the project's current code and imports.
2. Determine the installed/target Quickshell version when possible.
3. Prefer the API exposed by that version over examples from older configs or tutorials.
4. Never invent an API to make an implementation look plausible.

Treat official Quickshell and Qt documentation as authoritative for API shape. Treat this skill as architectural and implementation guidance.

## Read references selectively

Read only what the task needs:

- QML syntax, bindings, signals, components, models: `references/qml.md`
- `PanelWindow`, overlays, popups, screen behavior: `references/windows.md`
- Project organization, singletons, dependencies: `references/architecture.md`
- Data access, processes, IPC, services: `references/services.md`

## Default workflow

1. Inspect `shell.qml` and the nearest related components before editing.
2. Identify the current project conventions for config, theme, services, components, and imports.
3. Reuse existing services and shared state instead of introducing duplicates.
4. Prefer declarative bindings and event-driven updates.
5. Make the smallest coherent change that fits the architecture.
6. Verify multi-monitor implications for any window or screen-bound component.
7. Check lifecycle: object creation, loaders, timers, processes, connections, cleanup.
8. Run available QML linting or project checks.
9. Launch/reload Quickshell and use runtime errors to validate the result when execution is available.

## Core rules

- Prefer typed QML properties and function parameters where practical.
- Prefer property bindings over manually synchronizing the same state in multiple handlers.
- Prefer signals/events over polling.
- Prefer `qs.*` root-relative module imports on modern Quickshell when compatible with the project.
- Preserve an existing architecture unless the task explicitly calls for restructuring.
- Keep visual components focused on presentation and interaction.
- Keep system/application state in services or singletons when shared by multiple consumers.
- Avoid service -> widget dependencies. UI may depend on services; services should not depend on UI.
- Keep utility code side-effect free when possible.
- Do not spawn shell commands repeatedly when Quickshell or Qt already exposes a native API.
- Do not hard-code a monitor unless the feature is explicitly monitor-specific.
- Avoid giant `shell.qml` files. Compose the shell from focused types.

## QML editing discipline

When modifying a QML file:

- Preserve bindings unless imperative assignment is intentionally replacing them.
- Watch for accidental binding destruction caused by assigning to a bound property in JavaScript.
- Do not mix Qt Quick item anchors with `PanelWindow` edge-anchor semantics.
- Avoid combining anchors and layout-managed geometry for the same dimension unless the behavior is deliberate.
- Keep `id` local; expose intentional API through properties, aliases, signals, and functions.
- Prefer `Loader` or other lazy construction for expensive, rarely visible UI.

## Quickshell project check

For non-trivial tasks, inspect whether the project has:

- `shell.qml`
- `.qmlls.ini` next to the shell root
- theme/config singletons
- services directory
- reusable widgets/components
- popup/window layer
- compositor integration layer
- asset directory

Do not create missing layers just for symmetry. Add them only when the change benefits from them.

## Validation

At minimum, check:

- QML parses and imports resolve.
- No obvious circular dependency was introduced.
- No unnecessary fast polling timer was introduced.
- Windows use the correct screen and layer behavior.
- Newly shared state has a single owner.
- New lists/models do not recreate heavy delegates unnecessarily.
