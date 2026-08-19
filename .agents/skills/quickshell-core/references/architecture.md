# Quickshell architecture

A maintainable shell commonly separates concerns like this:

```text
quickshell/
├── shell.qml
├── config/
├── theme/
├── components/
├── widgets/
├── panels/
├── popups/
├── services/
├── utils/
└── assets/
```

Adapt to the existing project. Do not impose this tree if a different coherent structure already exists.

## Dependency direction

Prefer:

```text
shell / windows / widgets
          ↓
       services
          ↓
       utilities
```

Avoid services importing visual components.

## Singletons

Use a singleton for genuinely shared state such as:

- theme tokens;
- user configuration;
- audio/network/media state;
- compositor state;
- application/session state.

Do not make every helper a singleton. Stateless formatting logic can stay in utility code.

## State ownership

For each stateful value, be able to answer: "Which object owns the truth?"

Avoid two writable copies of the same state in separate widgets. Prefer one owner and bindings/signals from consumers.

## Large shell rule

When a component becomes difficult to reason about, split by responsibility rather than by arbitrary line count.

Good boundaries include:

- state acquisition vs rendering;
- panel section vs popup;
- reusable primitive vs feature composition;
- service vs widget.
