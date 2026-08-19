# Debugging workflow

## Start from terminal output

Run the shell in a way that preserves stderr/stdout using the command appropriate for the installed Quickshell version and project config.

Look first for:

- missing module/import;
- file not found;
- undefined property/type;
- JavaScript `TypeError`/`ReferenceError`;
- binding loop/circular binding;
- service availability failure.

## Reduce the problem

If a large popup is broken, isolate whether the failure comes from:

- window construction;
- model/service data;
- delegate rendering;
- interaction handler;
- animation/state transition.

Do not rewrite all layers at once.

## Version mismatch

When examples look syntactically correct but an import/type is unavailable, verify Quickshell version and current module names before changing architecture.

## QML language server

If the project targets modern Quickshell, keep `.qmlls.ini` next to the shell root when appropriate so Quickshell can manage QMLLS import configuration. Do not commit machine-specific generated content if the project's setup treats it as local state.

## Strategic logging

Log state transitions and inputs, not every frame. Remove noisy temporary logging after diagnosis unless it belongs to an intentional debug mode.

## Invisible UI checklist

Check:

- `visible` and `opacity`;
- width/height actually greater than zero;
- parent clipping;
- z/order/layer behavior;
- screen assignment;
- popup/window anchor context;
- state/transition leaving the component off-screen.
