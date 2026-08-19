# Hyprland integration patterns

## Prefer native Quickshell Hyprland integration

Modern Quickshell exposes a Hyprland module. Use the module supported by the project's installed version rather than manually reading compositor sockets unless there is a concrete need.

The exact module path and types are version-sensitive; verify them before editing.

## Avoid polling

Bad architecture:

```text
Timer -> hyprctl -j workspaces -> parse JSON -> update UI -> repeat
```

Preferred architecture:

```text
Hyprland state/events -> reactive QML state -> UI bindings
```

Polling wastes CPU, introduces latency, and can desynchronize multiple consumers.

## Active window

Keep presentation concerns separate from compositor data. Normalize title/class/app identity in the integration layer if several widgets need the same transformation.

## Workspace switching

A workspace button should dispatch a switch only on interaction. It should read active/occupied state from compositor-backed state, not optimistically maintain a second independent workspace truth unless temporary optimistic UI is explicitly required.

## Special workspaces / scratchpads

Treat special-workspace naming and semantics as configuration. Avoid hard-coding a single name across unrelated components if the project already exposes config for it.

## Robustness

Handle:

- monitor hotplug;
- empty workspace lists during startup/reload;
- windows disappearing between selection and action;
- compositor restart/reconnect if the existing API exposes connection state.
