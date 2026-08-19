---
name: quickshell-hyprland
description: Integrate Quickshell with Hyprland IPC. Use ONLY when introducing or changing Hyprland-specific integration code (Quickshell.Hyprland imports, dispatch calls, workspaces/monitors/toplevels state, special workspaces, Hyprland event handlers, Hyprland-aware panels). Do NOT trigger for general QML/UI work on an existing bar or widget.
license: MIT
compatibility: opencode
metadata:
  source: programmersd21/the_quickshell_book
  category: hyprland
---

# Quickshell + Hyprland

Use this skill for Quickshell features that depend on Hyprland compositor state or commands.

Read `references/hyprland.md` before implementing non-trivial compositor integration.

## API compatibility rule

Quickshell's Hyprland API has changed across versions. Never copy an import, type, property, or dispatch signature solely because it appears in an old shell config or tutorial.

Inspect the project's existing Hyprland imports and target Quickshell version first. Verify the current API when introducing a new call.

## Architecture

Centralize compositor state rather than having every widget query Hyprland independently.

Prefer:

```text
Hyprland event/API
      ↓
compositor service/state
      ↓
workspace bar / active window / launcher / OSD
```

## Event-driven rule

Do not poll `hyprctl` every 50-500ms to discover routine workspace/window/monitor changes when Quickshell's Hyprland integration exposes those changes reactively.

Use `hyprctl`/external process calls only where the native integration does not provide the needed operation or where a one-shot command is appropriate.

## Workspaces

When building workspace UI:

- preserve workspace identity;
- account for per-monitor state;
- distinguish active, occupied, urgent/special states when the available API exposes them;
- issue dispatches from user actions, not from render loops;
- avoid recreating all delegates for every tiny state change when a stable model can be used.

## Monitors

Do not assume one monitor or a fixed monitor name. If a component intentionally targets a specific monitor, make that dependency explicit.

## Commands

Keep dispatch construction in one integration layer when many UI components need it. Validate user-derived arguments before embedding them into external commands.
