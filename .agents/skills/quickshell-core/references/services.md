# Services, commands and data

## Native API first

Before using a shell command, check whether Quickshell or Qt exposes the capability directly.

Native/event-driven APIs are generally preferable for:

- compositor state;
- audio/PipeWire;
- media/MPRIS;
- power/UPower;
- system tray;
- notifications;
- Bluetooth;
- networking;
- D-Bus backed services.

Verify module availability in the target Quickshell version.

## Process usage

Use a process when no suitable native API exists or when invoking a one-shot external command is the right abstraction.

Avoid:

- a process per animation frame;
- short-interval polling through command-line tools;
- multiple widgets independently invoking the same command for the same state.

If several consumers need the same command-derived data, centralize it in one service.

## Event-driven data

Prefer this flow:

```text
system event -> service state -> bindings -> UI
```

over:

```text
timer -> process -> parse -> assign -> repeat
```

## Parsing

Keep parsing separate from presentation. A widget should consume already-normalized service state when possible.

## Caching

Cache only where it reduces meaningful repeated work. Define invalidation clearly. Do not turn stale cached state into a second source of truth.
