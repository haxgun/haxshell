# Qt/QML Essentials for Shell Development

Core Qt knowledge needed when building Quickshell shells. These are standard QML — not Quickshell-specific — but you'll use them constantly.

## Imports You'll Need

```qml
import QtQuick                // Rectangle, Image, Text, Item, MouseArea, Timer, etc.
import QtQuick.Layouts        // RowLayout, ColumnLayout, GridLayout
import QtQuick.Controls       // Button, Slider, TextField, ScrollView, Switch
import QtQuick.Effects        // MultiEffect (blur, shadow, mask, colorize)
```

## Focus Management (Launchers, Search)

```qml
import QtQuick
import QtQuick.Controls

// FocusScope groups focus — essential for search bars and modals
FocusScope {
    id: launcher

    // Grab focus when launcher opens
    onVisibleChanged: if (visible) searchField.forceActiveFocus()

    TextField {
        id: searchField
        focus: true  // receives focus when scope activates
        placeholderText: "Search..."

        Keys.onEscapePressed: launcher.visible = false
        Keys.onDownPressed: resultsList.incrementCurrentIndex()
    }

    ListView {
        id: resultsList
        // ...
        Keys.onReturnPressed: launch(currentItem.modelData)
    }
}
```

Key: `forceActiveFocus()` grabs focus even across FocusScopes. `focus: true` only works within the current scope.

## Flickable (Scrollable Panels)

```qml
Flickable {
    anchors.fill: parent
    contentHeight: column.implicitHeight  // MUST set content size
    clip: true                             // clip overflow

    Column {
        id: column
        width: parent.width
        // ... tall content
    }
}

// Or use ScrollView which wraps Flickable + adds scrollbar
ScrollView {
    anchors.fill: parent
    contentWidth: availableWidth  // prevents horizontal scroll

    ColumnLayout {
        width: parent.width
        // ... content
    }
}
```

## States and Transitions

Cleaner than chains of Behaviors when multiple properties change together:

```qml
Rectangle {
    id: panel

    states: [
        State {
            name: "open"
            PropertyChanges { target: panel; opacity: 1; y: 0 }
        },
        State {
            name: "closed"
            PropertyChanges { target: panel; opacity: 0; y: -panel.height }
        }
    ]

    transitions: [
        Transition {
            from: "closed"; to: "open"
            NumberAnimation { properties: "opacity,y"; duration: 200; easing.type: Easing.OutCubic }
        },
        Transition {
            from: "open"; to: "closed"
            NumberAnimation { properties: "opacity,y"; duration: 150; easing.type: Easing.InCubic }
        }
    ]

    state: drawerOpen ? "open" : "closed"
}
```

## Color Manipulation

```qml
// Creation
Qt.rgba(1, 0, 0, 0.5)                    // from RGBA (0.0-1.0)
Qt.hsla(0.5, 1, 0.5, 0.8)                // from HSLA
"#80ff0000"                                // hex with alpha (#AARRGGBB)

// Modification
Qt.darker(color, 1.5)                     // darken by factor
Qt.lighter(color, 1.3)                    // lighten by factor
Qt.alpha(color, 0.5)                      // set alpha, keep RGB
Qt.tint(baseColor, tintColor)             // blend tint over base

// Decompose
color.r, color.g, color.b, color.a        // RGB components (0.0-1.0)
color.hslHue, color.hslSaturation, color.hslLightness  // HSL components

// Common theming pattern — derive state colors from base
property color hoverColor: Qt.lighter(baseColor, 1.1)
property color pressedColor: Qt.darker(baseColor, 1.1)
property color disabledColor: Qt.alpha(baseColor, 0.4)
```

## Gradients

```qml
Rectangle {
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#00000000" }  // transparent top
        GradientStop { position: 1.0; color: "#80000000" }  // semi-opaque bottom
    }
}

// Horizontal gradient (Qt6)
Rectangle {
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "red" }
        GradientStop { position: 1.0; color: "blue" }
    }
}
```

## Common Qt Utility Functions

```qml
// URLs
Qt.openUrlExternally("https://example.com")  // open in default browser
Qt.resolvedUrl("shaders/blur.qsb")           // resolve relative path

// Date/Time formatting
Qt.formatDateTime(date, "hh:mm")              // "14:30"
Qt.formatDateTime(date, "ddd, MMM d")         // "Sat, Apr 12"
Qt.formatDate(date, Qt.DefaultLocaleLongDate) // locale-aware

// Locale
Qt.locale()                                   // system locale

// Exit
Qt.quit()                                     // exit the shell

// Dynamic binding
property: Qt.binding(() => someExpression)     // re-establish broken binding
```

## Key QtQuick Properties

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

**Anchors (most common layout in shells):**
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

// Spring for natural motion
SpringAnimation { spring: 2; damping: 0.2 }

// Sequential / Parallel
SequentialAnimation {
    NumberAnimation { target: item; property: "opacity"; to: 0; duration: 150 }
    NumberAnimation { target: item; property: "y"; to: -100; duration: 200 }
}
```
