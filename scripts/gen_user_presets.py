#!/usr/bin/env python3
"""Split builtin color presets into user JSON themes.

Keeps a curated set of builtins in core/internal/natonctl/presets.go and
writes every other preset as a user theme JSON in quickshell/presets/.
The ANSI slot -> semantic key mapping mirrors themeFromBuiltin in presets.go.
"""

import json
import os
import re
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRESETS_SOURCE = "/tmp/opencode/presets_sorted.go"
PRESETS_FILE = os.path.join(BASE, "core/internal/natonctl/presets.go")
OUT_DIR = os.path.join(BASE, "quickshell/presets")

KEEP = {"Aether", "Dracula", "Nord", "Catppuccin Mocha", "Gruvbox Dark", "Tokyo Night"}

SLOT_KEYS = [
    "red", "green", "yellow", "blue", "magenta", "cyan",
    "brightRed", "brightGreen", "brightYellow", "brightBlue",
    "brightMagenta", "brightCyan",
]

SEMANTIC = {
    0: "background",
    7: "foreground",
    8: "layer",
    15: "brightForeground",
}


def parse_presets(path):
    src = open(path, encoding="utf-8").read()
    out = []
    for m in re.finditer(
        r"\{Name: \"([^\"]+)\"(?:, Accent: \"([^\"]+)\")?, Colors: \[16\]string\{((?:.*?\n)*?)\t\}\}",
        src,
    ):
        name, accent, body = m.group(1), m.group(2), m.group(3)
        colors = re.findall(r"\"(#[0-9A-Fa-f]{6})\"", body)
        if len(colors) != 16:
            print(f"skip {name}: {len(colors)} colors")
            continue
        out.append({"name": name, "accent": accent, "colors": colors})
    return out


def to_theme(t):
    c = t["colors"]
    th = {
        "name": t["name"],
        "accent": t["accent"],
        "background": c[0],
        "foreground": c[7],
        "layer": c[8],
        "selection": c[8],
        "muted": c[8],
    }
    for i, k in enumerate(SLOT_KEYS):
        th[k] = c[i + 1]
    th["brightForeground"] = c[15]
    th["colors"] = c
    return th


def main():
    themes = parse_presets(PRESETS_SOURCE)
    if len(themes) != 55:
        print(f"expected 55 themes, got {len(themes)}; aborting")
        sys.exit(1)

    keep = [t for t in themes if t["name"] in KEEP]
    move = [t for t in themes if t["name"] not in KEEP]
    if len(keep) != len(KEEP):
        missing = KEEP - {t["name"] for t in keep}
        print(f"missing keep themes: {sorted(missing)}")
        sys.exit(1)

    os.makedirs(OUT_DIR, exist_ok=True)
    for t in move:
        slug = re.sub(r"[^a-z0-9]+", "-", t["name"].lower()).strip("-")
        path = os.path.join(OUT_DIR, f"{slug}.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(to_theme(t), f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"wrote {os.path.relpath(path, BASE)}")

    # Rewrite presets.go with only the kept themes, preserving header.
    src = open(PRESETS_FILE, encoding="utf-8").read()
    header = src[: src.index("var presetThemes = []presetTheme{") + len("var presetThemes = []presetTheme{")]

    def render(t):
        lines = ['\t{Name: "%s",' % t["name"]]
        if t["accent"]:
            lines[0] += ' Accent: "%s",' % t["accent"]
        lines[0] += " Colors: [16]string{"
        for i, c in enumerate(t["colors"]):
            lines.append('\t\t"%s",' % c)
        lines.append("\t}},")
        return "\n".join(lines)

    body = "\n" + "\n".join(render(t) for t in keep) + "\n}\n"
    with open(PRESETS_FILE, "w", encoding="utf-8") as f:
        f.write(header + body)

    print(f"kept {len(keep)} builtins: {sorted(t['name'] for t in keep)}")


if __name__ == "__main__":
    main()
