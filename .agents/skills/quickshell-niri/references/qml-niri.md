# qml-niri reference

Repository: `imiric/qml-niri`

`qml-niri` is a Qt 6 QML plugin that talks to niri through its IPC protocol and exposes compositor state as native QML objects/models.

## Import and entry point

```qml
import Niri

Niri {
    id: niri
    Component.onCompleted: connect()
}
```

The environment must provide a valid `NIRI_SOCKET` for the running compositor.

## Why prefer it

The plugin already provides event-driven updates for compositor changes, so Quickshell code does not need to:

- poll `niri msg`;
- parse the event stream manually;
- maintain separate subprocesses for workspaces and windows;
- reconstruct focused state from unrelated events.

## Exposed object families

The plugin documents these primary QML types/concepts:

- `Niri` — main connection and action object;
- `WorkspaceModel` — workspace list model;
- `WindowModel` — window list model;
- `Window` — individual window data;
- `Overview` — current overview state.

Only rely on properties and methods present in the target plugin version.

## Core state

Prefer these plugin-owned properties:

```qml
niri.workspaces
niri.windows
niri.focusedWindow
niri.overview
niri.keyboardLayouts
```

Useful reactive bindings:

```qml
Text {
    text: niri.focusedWindow?.title ?? ""
}

property bool overviewOpen: niri.overview.isOpen
```

## Workspace model

Use `niri.workspaces` directly as a QML model:

```qml
Repeater {
    model: niri.workspaces

    delegate: Rectangle {
        required property int id
        // Depending on Qt/model style in the target project, roles may instead
        // be accessed via `model.<role>`. Preserve the project's working style.
    }
}
```

The plugin's documented workspace roles include identity/presentation/focus information. Inspect the installed API before assuming an unfamiliar role name.

Useful helpers documented by the plugin include:

```qml
niri.workspaces.get(row)
niri.workspaces.indexOfId(id)
```

The workspace model also supports a maximum visible count. Prefer the model's feature when it matches the UI requirement rather than duplicating it in JavaScript.

## Workspace actions

Typed methods documented by qml-niri include:

```qml
niri.focusWorkspace(index)
niri.focusWorkspaceById(id)
niri.focusWorkspaceByName(name)
```

Prefer ID-based actions when acting on an item obtained from the workspace model.

## Window model

Use `niri.windows` as the window list model and `niri.focusedWindow` for the focused client.

Typical documented actions:

```qml
niri.focusWindow(id)
niri.closeWindow(id)
niri.closeWindowOrFocused()
```

Always handle the no-focused-window case:

```qml
text: niri.focusedWindow?.title ?? "No focused window"
```

## Overview

The plugin exposes overview state through `niri.overview`, including whether it is open, and provides a typed overview toggle action.

Prefer compositor truth:

```qml
visible: niri.overview.isOpen
```

rather than a manually mirrored boolean.

## Action results

Typed actions return an object shaped conceptually as:

```text
{
  ok: boolean,
  error: string when failed
}
```

Check it when the user needs feedback or when subsequent behavior depends on success.

Per-action failures should not be confused with connection-level `errorOccurred` events.

## Raw-action escape hatch

`sendRawAction()` can send a niri Action represented as a JSON-shaped object.

Use it only if no typed wrapper exists in the installed plugin version. It is intentionally less safe because the plugin cannot schema-validate arbitrary actions.

## Icons

The plugin can resolve application icons through XDG desktop entries and exposes icon information in its window model. Prefer that data over launching external desktop-file lookup commands from each delegate.

## Logging

For plugin troubleshooting, Qt logging categories can be enabled through `QT_LOGGING_RULES`. Consult the qml-niri README for the category names supported by the installed version.

## Installation awareness

The plugin can be installed as a Qt QML module and its repository also provides Nix integration. Do not bake a distro-specific installation command into project code.

When debugging an import failure, check:

1. whether `qml-niri` is installed;
2. the Qt 6 QML import path;
3. whether Quickshell uses the same Qt installation/path;
4. `NIRI_SOCKET` availability at runtime.

## Primary source

- `https://github.com/imiric/qml-niri`
