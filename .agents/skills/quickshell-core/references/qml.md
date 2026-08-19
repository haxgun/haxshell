# QML practices for Quickshell

## Prefer declarative state

Use bindings for derived values:

```qml
property int panelHeight: 40
property int iconSize: Math.round(panelHeight * 0.55)
```

Avoid duplicating derived state with handlers unless there is a real reason to break the binding.

## Typed properties and functions

Prefer explicit types when they improve correctness:

```qml
property int count: 0
property bool expanded: false
signal activated(index: int)

function clamp(value: real, min: real, max: real): real {
    return Math.max(min, Math.min(max, value));
}
```

## Components

- QML files defining reusable types should use PascalCase names.
- `id` values should be camelCase.
- Expose a small intentional public API through properties/signals/functions.
- Keep implementation objects private to the component.

## Imports

Modern Quickshell supports config-root-relative imports such as:

```qml
import qs.widgets
import qs.services
```

Prefer them over fragile chains of `../..` when the project's target version supports them.

Never change import style project-wide as a side effect of an unrelated task.

## Models and delegates

- Keep delegates lightweight.
- Avoid expensive image decoding at full resolution for tiny icons.
- When a JavaScript expression would cause an entire changing model to be recreated, check whether the installed Quickshell version provides a more suitable model wrapper.
- Keep stable identity when list animations/state depend on it.

## Signals instead of polling

If the underlying service emits changes, consume those changes instead of querying it on a short `Timer` interval.

Use timers for actual time-based behavior, not as a substitute for an event source.

## Layout safety

- Use `RowLayout`/`ColumnLayout` when items should participate in layout sizing.
- Do not simultaneously fight a layout with hardcoded `x/y/width` values unless necessary.
- Be careful when animating properties that trigger relayout every frame.

## Binding safety

This starts as a binding:

```qml
width: parent.width / 2
```

An imperative assignment such as `width = 200` replaces that binding. Do so only intentionally.
