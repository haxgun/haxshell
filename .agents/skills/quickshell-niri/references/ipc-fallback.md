# Raw niri IPC fallback

Use this reference only when `qml-niri` is unavailable or cannot represent a required feature.

## Decision rule

Before adding raw IPC, establish which case applies:

1. qml-niri already supports it -> use the typed plugin API;
2. qml-niri lacks a typed method but supports `sendRawAction()` -> prefer that;
3. the project cannot use qml-niri -> use a centralized raw IPC service.

Do not create a second live compositor-state pipeline merely because calling `niri msg` looks easier locally.

## Prefer one event stream

If a raw backend is genuinely required, prefer:

```text
one niri event stream
       ↓
central state service
       ↓
all interested components
```

over:

```text
WorkspaceWidget -> niri msg workspaces every 250ms
TitleWidget     -> niri msg focused-window every 250ms
OutputWidget    -> niri msg outputs every 500ms
```

## Quickshell process pattern

Conceptually, a fallback implementation may use `Quickshell.Io.Process` and a line parser:

```qml
import Quickshell.Io

Process {
    running: true
    command: ["niri", "msg", "--json", "event-stream"]

    stdout: SplitParser {
        onRead: line => Backend.handleEventLine(line)
    }
}
```

Treat exact Quickshell parser/property names as version-sensitive. Match the target project's working API.

## Defensive parsing

Unknown or malformed events must not crash the shell:

```qml
function handleEventLine(line) {
    let event
    try {
        event = JSON.parse(line)
    } catch (e) {
        console.warn("Invalid niri IPC JSON:", e)
        return
    }

    // Handle known variants; safely ignore future unknown ones.
}
```

## State identity

Use compositor IDs rather than anonymous array positions for workspaces/windows whenever available.

Expect dynamic workspace creation/removal and window disappearance between related events.

## Actions

Prefer direct argument arrays over shell-concatenated strings. Verify the action form against the installed niri version.

Do not pass unsanitized user-controlled strings through `sh -c`.

## Restart behavior

A compositor restart can terminate the event process. If reconnect logic is needed, use bounded backoff rather than a tight restart loop.

## Primary documentation

- `https://niri-wm.github.io/niri/IPC.html`
- `https://niri-wm.github.io/niri/niri_ipc/enum.Request.html`
