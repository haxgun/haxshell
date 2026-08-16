# Qt Visual Effects in Quickshell

Quickshell does NOT abstract Qt away. You write native QML with full access to QtQuick. For visual effects, you need to know these Qt modules and patterns directly.

## The Effect Stack

```
MultiEffect (import QtQuick.Effects)     ← Primary. Blur, shadow, mask, colorize
ShaderEffect (import QtQuick)            ← Custom GLSL for specialized effects
Canvas (import QtQuick)                  ← Custom 2D drawing (graphs, waves)
layer.enabled + layer.effect             ← Foundation for ALL effect composition
```

## 1. MultiEffect — The Workhorse

`import QtQuick.Effects` — this is the modern Qt6 way. Do NOT use Qt5Compat.GraphicalEffects.

### Blur

```qml
import QtQuick
import QtQuick.Effects

MultiEffect {
    source: wallpaperImage
    anchors.fill: source
    blurEnabled: true
    blur: 0.8          // 0.0 to 1.0
    blurMax: 75         // max blur radius in pixels
    saturation: 0.2     // optional: desaturate blurred content
}
```

### Drop Shadow

```qml
Item {
    id: card
    // ... card content

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 0.5           // 0.0 to 1.0
        shadowColor: "#40000000"
        shadowOpacity: 0.8
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 4
        blurMax: 32
        autoPaddingEnabled: true  // expand bounds to fit shadow
    }
}
```

### Colorize / Tint

```qml
MultiEffect {
    source: iconImage
    colorization: 1.0              // 0.0 (none) to 1.0 (full)
    colorizationColor: "#ff4081"
    brightness: 0.2                // adjust lightness
}
```

### Mask (Rounded Corners, Custom Shapes)

```qml
Rectangle {
    id: content
    // ... content to mask
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}

// The mask shape (invisible, rendered offscreen)
Item {
    id: mask
    anchors.fill: content
    layer.enabled: true
    visible: false  // must be invisible — only used as mask source

    Rectangle {
        anchors.fill: parent
        radius: 20
    }
}
```

### Inverted Mask (Cut-Out / Inner Border)

```qml
Rectangle {
    layer.enabled: true
    layer.effect: MultiEffect {
        maskSource: innerMask
        maskEnabled: true
        maskInverted: true        // invert = show everything EXCEPT the mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Item {
        id: innerMask
        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: borderWidth
            radius: innerRadius
        }
    }
}
```

### Combined Effects

MultiEffect can do blur + shadow + mask simultaneously:

```qml
layer.effect: MultiEffect {
    blurEnabled: true
    blur: 0.6
    blurMax: 50

    shadowEnabled: true
    shadowBlur: 0.4
    shadowColor: "#30000000"
    shadowVerticalOffset: 4

    maskEnabled: true
    maskSource: roundedMask
}
```

## 2. ShaderEffect — Custom GLSL

For specialized effects (ripples, wallpaper transitions, weather visualizations):

```qml
ShaderEffect {
    required property Item source
    required property Item maskSource

    // Load pre-compiled shader (.qsb = Qt Shader Baker output)
    fragmentShader: Quickshell.shellPath("shaders/opacitymask.frag.qsb")
}
```

### Ripple Effect Example

```qml
ShaderEffect {
    property real rippleCenterX: 0.5
    property real rippleCenterY: 0.5
    property real rippleRadius: 0
    property real rippleOpacity: 0
    property real widthPx: width
    property real heightPx: height
    property vector4d rippleCol: Qt.vector4d(r, g, b, a)

    fragmentShader: Qt.resolvedUrl("shaders/ripple.frag.qsb")
}
```

### Shader Compilation

GLSL source (.frag) must be compiled to .qsb for Qt6:
```bash
qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o effect.frag.qsb effect.frag
```

Or use Qt Shader Baker in your build system.

### Wallpaper Transitions with ShaderEffectSource

```qml
ShaderEffectSource {
    id: wallpaperTexture
    sourceItem: wallpaperImage
    hideSource: true       // hide original, show only through effect
    live: true             // update when source changes
    textureSize: Qt.size(width, height)  // render at specific size
}

ShaderEffect {
    property var source: wallpaperTexture
    property real progress: transitionProgress  // 0.0 to 1.0
    fragmentShader: Qt.resolvedUrl("shaders/wp_fade.frag.qsb")
}
```

## 3. The Layer System — Foundation for Effects

`layer.enabled: true` renders the item to an offscreen texture. Required for:
- Applying any `layer.effect`
- Combining multiple visual elements before applying effects
- Rounded clipping with proper antialiasing

```qml
Rectangle {
    radius: 20
    layer.enabled: true  // renders to FBO, enables proper rounded clipping

    // Children will be clipped to the rounded rectangle
    Image {
        anchors.fill: parent
        source: "wallpaper.jpg"
    }
}
```

**Performance warning:** Each `layer.enabled: true` creates a framebuffer object (FBO). Don't enable layers on items that don't need effects — it doubles the render cost for that subtree.

### Nested Layers for Complex Composition

```qml
// Outer layer for shadow
Item {
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; ... }

    // Inner layer for blur + mask
    Rectangle {
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            maskEnabled: true
            maskSource: roundedMask
        }

        Image { anchors.fill: parent; source: wallpaper }
    }
}
```

## 4. Canvas — Custom 2D Drawing

For graphs, visualizers, and custom UI:

```qml
Canvas {
    id: graph
    width: 200; height: 100

    property var values: []

    onValuesChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.strokeStyle = "#ff4081";
        ctx.lineWidth = 2;
        ctx.beginPath();
        for (var i = 0; i < values.length; i++) {
            var x = (i / values.length) * width;
            var y = height - (values[i] * height);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.stroke();
    }
}
```

## 5. Common Qt Types You Need

These are Qt, not Quickshell — but you'll use them constantly:

```qml
import QtQuick               // Rectangle, Image, Text, Item, MouseArea, Timer, etc.
import QtQuick.Layouts        // RowLayout, ColumnLayout, GridLayout
import QtQuick.Controls       // Button, Slider, TextField, ScrollView, Switch
import QtQuick.Effects        // MultiEffect (blur, shadow, mask, colorize)
```

### Key QtQuick Properties for Shell Development

**Opacity & Visibility:**
```qml
opacity: 0.8              // 0.0 (transparent) to 1.0 (opaque)
visible: false             // hides but keeps in layout
clip: true                 // clip children to bounds
```

**Transforms:**
```qml
scale: 0.5                 // uniform scale
rotation: 45               // degrees
transformOrigin: Item.Center
```

**Anchors (most common layout system in shells):**
```qml
anchors.fill: parent
anchors.centerIn: parent
anchors.left: parent.left
anchors.margins: 10
anchors.leftMargin: 20     // override specific margin
```

**Animations:**
```qml
Behavior on opacity { NumberAnimation { duration: 200 } }
Behavior on color { ColorAnimation { duration: 200 } }
Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
```

## 6. Performance Guidelines

1. **Minimize `layer.enabled: true`** — each creates an FBO. Only enable when you need effects.
2. **Use `Image { asynchronous: true; sourceSize: Qt.size(w,h) }`** — decode at display size, off main thread.
3. **Pre-compile shaders to .qsb** — avoids runtime compilation overhead.
4. **Disable effects when not visible** — `blurEnabled: false` when panel is hidden.
5. **Use `MultiEffect` over `Qt5Compat.GraphicalEffects`** — it's GPU-optimized for Qt6.
6. **Noctalia pattern: disable effects in performance mode:**
   ```qml
   layer.enabled: Settings.data.general.enableShadows && !performanceMode
   ```

## 7. Compositor-Level Blur

For blurring what's BEHIND your shell window (like a translucent bar), this is a Wayland protocol feature, not a QML effect. Quickshell provides:

```qml
import Quickshell.Wayland

PanelWindow {
    // Request compositor blur behind this surface
    // (requires compositor support — Hyprland supports this)
    color: "#80000000"  // semi-transparent background
    // The compositor handles the blur of content behind the window
}
```

Hyprland enables this via window rules:
```conf
# hyprland.conf
windowrulev2 = blur, class:quickshell
layerrule = blur, quickshell
layerrule = ignorealpha 0.3, quickshell
```

This is much more performant than blurring in QML — the compositor does it at the GPU level.

---

For color manipulation (Qt.rgba/darker/lighter/alpha), gradients, and other Qt-general patterns, see `qt-essentials.md`.
