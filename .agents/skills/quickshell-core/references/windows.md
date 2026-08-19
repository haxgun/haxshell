# Quickshell windows

## Pick the correct window type

Use the Quickshell window type intended for the behavior rather than emulating desktop-shell behavior with a normal Qt window.

Typical categories:

- edge-attached panel/bar
- floating shell window
- anchored popup/overlay
- temporary on-screen display

Verify exact type names and properties against the target Quickshell version.

## Panel rules

For an edge panel:

- Attach to the intended screen edge using the panel's edge-anchor API.
- Reserve space only when ordinary windows should avoid the panel.
- Keep panel focus disabled unless keyboard interaction genuinely requires it.
- Consider whether the panel belongs on one screen or all screens.

`PanelWindow` edge anchors are booleans describing compositor edges. They are not the same as `Item.anchors` bindings to another QML item.

## Exclusive space

Use an exclusive zone when maximized/tiled windows must not overlap a bar. Do not reserve space for overlays, notifications, menus, or transient surfaces that should float over content.

## Multi-monitor

Never assume `Screen.width` means the monitor the shell window is on.

For multi-screen shells:

- bind each shell window to an explicit Quickshell screen object when needed;
- generate per-screen windows from the current screen list when the shell should appear everywhere;
- ensure popups use the correct parent/screen context;
- test monitor add/remove behavior if the feature is long-lived.

## Popups and overlays

For temporary UI:

- do not reserve exclusive space;
- ensure focus behavior matches interaction needs;
- close predictably on outside click, Escape, state change, or parent disappearance where appropriate;
- construct expensive popup content lazily if it is rarely shown.
