---
name: quickshell-niri
description: Integrate Quickshell with the niri Wayland compositor using the qml-niri plugin (`import Niri`) whenever available. Use for niri workspaces, windows, focus state, overview, keyboard layout state, compositor actions, niri-aware bars, launchers, workspace indicators, and multi-monitor shell behavior. Fall back to raw niri IPC only when qml-niri cannot provide the required capability.
license: MIT
compatibility: opencode
metadata:
  category: compositor
  compositor: niri
  preferred_backend: qml-niri
---

# Quickshell + niri

Use this skill whenever Quickshell code depends on niri compositor state or actions.

**Preferred integration: `qml-niri` (`import Niri`).**

Read `references/qml-niri.md` before implementing or refactoring niri integration. Read `references/ipc-fallback.md` only when the plugin does not expose a required capability or is unavailable in the target environment.

## Source-of-truth rule

Do not invent a `Quickshell.Niri` module.

The preferred external plugin is `qml-niri`, whose QML module is:

```qml
import Niri
```

Before editing code:

1. inspect the project's Quickshell and Qt versions;
2. check whether `qml-niri` is installed or already imported;
3. inspect any existing compositor service/singleton;
4. preserve the project's established service boundary;
5. verify unfamiliar properties/methods against the plugin version actually installed.

## Backend priority

Choose backends in this order:

1. existing project abstraction backed by `qml-niri`;
2. direct `qml-niri` usage when introducing niri integration;
3. existing project-local niri IPC service;
4. raw `niri msg` / event-stream integration only as a fallback.

Do not add a parallel CLI event-stream service to a project that already uses `qml-niri`.

## Architecture

Prefer one long-lived compositor service:

```text
qml-niri Niri object
       ↓
NiriService / compositor facade
       ↓
bar / workspace switcher / active window / overview / launcher
```

The `Niri` object already maintains event-driven compositor state. UI components should bind to that state instead of launching subprocesses or maintaining duplicate copies.

## Connection lifecycle

Create the `Niri` instance at a stable shell/service scope and connect once.

Conceptual pattern:

```qml
import Niri

Niri {
    id: niri
    Component.onCompleted: connect()

    onConnected: {
        // service is ready
    }

    onErrorOccurred: function(error) {
        console.error("niri IPC:", error)
    }
}
```

Do not create one `Niri` connection per widget, delegate, monitor row, or popup.

## Reactive state

Prefer plugin-owned models/properties:

- `niri.workspaces`
- `niri.windows`
- `niri.focusedWindow`
- `niri.overview`
- keyboard layout state exposed by the installed plugin version

Bind UI directly to models and roles rather than periodically rebuilding state.

## Workspaces

Prefer `niri.workspaces` as the live model.

Use stable workspace IDs for actions when possible. Do not treat a workspace's current visual index as durable identity.

Typical actions include:

```qml
niri.focusWorkspace(index)
niri.focusWorkspaceById(id)
niri.focusWorkspaceByName(name)
```

For bounded UI such as a fixed-width workspace strip, use the model's supported limiting/filtering facilities instead of manually polling and slicing compositor output.

## Windows

Prefer `niri.windows` for window lists and `niri.focusedWindow` for the focused window.

Typical actions include:

```qml
niri.focusWindow(id)
niri.closeWindow(id)
niri.closeWindowOrFocused()
```

Window references may become invalid as clients close. UI code must tolerate `focusedWindow === null` and disappearing rows.

## Overview

Use the plugin's overview state and typed action when available:

```qml
property bool overviewOpen: niri.overview.isOpen

function toggleOverview() {
    const result = niri.toggleOverview()
    if (!result.ok)
        console.warn(result.error)
}
```

Do not maintain a second guessed `overviewOpen` boolean that can desynchronize from the compositor.

## Actions and results

Typed action methods return result objects. Check failures when correctness matters:

```qml
const result = niri.focusWorkspaceById(workspaceId)
if (!result.ok)
    console.warn("Failed to focus workspace:", result.error)
```

Connection-level failures belong to `onErrorOccurred`; per-action failures should be handled from the returned result.

## Raw actions

Use `sendRawAction()` only when the plugin lacks a typed wrapper for a niri action.

Prefer:

```text
typed qml-niri method
```

over:

```text
sendRawAction
```

over:

```text
spawn niri msg from QML
```

Raw actions are version-sensitive and receive less validation.

## Multi-monitor behavior

Do not assume:

- one output;
- a fixed workspace count;
- globally stable workspace positions;
- hardcoded output names such as `eDP-1` or `DP-1`.

Use model roles and compositor-provided identities. Keep screen/output mapping logic centralized when the UI needs per-monitor filtering.

## Performance rules

Never poll `niri msg` on a timer for state already exposed by `qml-niri`.

Do not copy large models into JavaScript arrays on every update unless the UI genuinely needs a transformed model. Prefer QML model/view patterns and proxy/filter models where appropriate.

## Failure handling

The shell must degrade gracefully if:

- `NIRI_SOCKET` is unavailable;
- qml-niri cannot connect;
- niri restarts;
- the installed plugin version lacks a method found in newer documentation.

Never replace a working typed integration with subprocess polling as a first response to an error.
