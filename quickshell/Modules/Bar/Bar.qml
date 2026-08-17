import "."
import "../../Common"
import "../../Widgets"
import QtQuick
// Bar.qml - Quickshell bar window container
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    // Public Component References
    property var appDrawer: null
    property var calendarPopup: null
    property var controlCenterPopup: null
    property var brightnessPopup: null
    property var wifiPopup: null
    property var bluetoothPopup: null
    property var audioPopup: null
    property var batteryPopup: null
    property var notificationPopup: null
    property var trayMenuPopup: null
    property var keyboardLayoutPopup: null
    property var settingsPopup: null
    property var powerPopup: null
    property var systemPopup: null
    property var mediaPopup: null
    property var osd: null

    function closeBarFlyouts() {
        let popups = [root.appDrawer, root.calendarPopup, root.brightnessPopup, root.wifiPopup, root.bluetoothPopup, root.audioPopup, root.batteryPopup, root.notificationPopup, root.trayMenuPopup, root.keyboardLayoutPopup, root.settingsPopup, root.powerPopup, root.systemPopup, root.mediaPopup, root.controlCenterPopup];
        for (let p of popups) {
            if (p && typeof p.isOpen !== "undefined")
                p.isOpen = false;

        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope
            required property var modelData
            property string targetPos: ""
            property bool barMoveActive: false
            property bool barHidden: false

            function nearestEdge(sx, sy) {
                let w = modelData.width
                let h = modelData.height
                let nx = w > 0 ? Math.max(0, Math.min(1, sx / w)) : 0.5
                let ny = h > 0 ? Math.max(0, Math.min(1, sy / h)) : 0.5
                let edge = "top"
                let best = ny
                if (1 - ny < best) { edge = "bottom"; best = 1 - ny }
                if (nx < best) { edge = "left"; best = nx }
                if (1 - nx < best) { edge = "right"; best = 1 - nx }
                return edge
            }

            function finishBarDrag() {
                if (targetPos !== "" && targetPos !== Config.barPosition) {
                    Config.barPosition = targetPos
                    SettingsStore.setValue("barPosition", targetPos)
                }
            }

            function revealBar() {
                hideTimer.stop()
                barHidden = false
            }

            function scheduleHide() {
                if (!Config.barAutoHide) return
                hideTimer.interval = Math.max(0, Config.barAutoHideDelay) * 1000
                hideTimer.restart()
            }

            Timer {
                id: hideTimer
                repeat: false
                onTriggered: screenScope.barHidden = true
            }

            Connections {
                target: Config
                function onBarAutoHideChanged() {
                    if (Config.barAutoHide) screenScope.scheduleHide()
                    else screenScope.revealBar()
                }
            }

            Tooltip {
                id: barTooltip
                screenInfo: modelData
            }

            PanelWindow {
                id: window

                readonly property bool posTop: Config.barPosition === "top"
                readonly property bool posBottom: Config.barPosition === "bottom"
                readonly property bool posLeft: Config.barPosition === "left"
                readonly property bool posRight: Config.barPosition === "right"
                readonly property bool vertical: posLeft || posRight
                readonly property int screenWidth: modelData.width || width
                readonly property int screenHeight: modelData.height || height

                screen: modelData
                // Wayland LayerShell Integration
                WlrLayershell.namespace: "quickshell-bar"
                WlrLayershell.layer: WlrLayer.Top
                implicitWidth: window.vertical ? Config.barHeight + Config.barMargin : 0
                implicitHeight: window.vertical ? 0 : Config.barHeight + Config.scaledBarTopMargin + Config.scaledBarBottomMargin
                color: "#00000000"

                anchors {
                    top: window.vertical || window.posTop
                    bottom: window.vertical || window.posBottom
                    left: !window.vertical || window.posLeft
                    right: !window.vertical || window.posRight
                }

                readonly property int hideShift: (window.vertical ? Config.barHeight + Config.barMargin : Config.barHeight + Config.scaledBarTopMargin + Config.scaledBarBottomMargin) - Config.scaledSize(4)

                margins {
                    top: window.posTop && screenScope.barHidden ? -window.hideShift : 0
                    bottom: window.posBottom && screenScope.barHidden ? -window.hideShift : 0
                    left: window.posLeft && screenScope.barHidden ? -window.hideShift : 0
                    right: window.posRight && screenScope.barHidden ? -window.hideShift : 0
                }

                exclusionMode: (Config.barAutoHide || screenScope.barHidden) ? ExclusionMode.Ignore : ExclusionMode.Auto

                HoverHandler {
                    id: barHover
                    onHoveredChanged: hovered ? screenScope.revealBar() : screenScope.scheduleHide()
                }

                Rectangle {
                    id: barSurface

                    readonly property bool vertical: window.vertical
                    property Item leftIsland: null
                    property Item rightIsland: null

                    x: vertical ? (window.posLeft ? Config.barMargin : 0) : Config.barMargin
                    y: Config.scaledBarTopMargin
                    width: vertical ? Config.barHeight : parent.width - Config.barMargin * 2
                    height: vertical ? parent.height - Config.scaledBarTopMargin - Config.scaledBarBottomMargin : Config.barHeight
                    radius: Config.scaledBarRadius
                    color: Config.barStyle === "solid" ? Config.barBackgroundBg : "#00000000"

                    Rectangle {
                        visible: Config.barStyle === "solid" && Config.barShadowsEnabled
                        x: 0
                        y: Config.shellShadowOffsetY
                        width: parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Config.shellShadowColor
                        opacity: 0.55
                        z: -1
                    }

                    Rectangle {
                        visible: Config.barStyle === "solid" && Config.barBordersEnabled
                        anchors.fill: parent
                        anchors.margins: Config.innerBorderMargin
                        radius: Math.max(0, barSurface.radius - Config.innerBorderMargin)
                        color: "#00000000"
                        border.color: Config.barBorderColor
                        border.width: Config.barBordersEnabled ? 1 : 0
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.closeBarFlyouts()
                    }

                    // Left-drag on empty bar area repositions the bar to the nearest edge.
                    // Placed below widgets so their own mouse handling wins.
                    MouseArea {
                        id: barDragArea
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        preventStealing: true
                        property bool dragging: false
                        property point pressPos: Qt.point(0, 0)
                        property real pressScreenX: 0
                        property real pressScreenY: 0

                        onPressed: (mouse) => {
                            dragging = false
                            pressPos = Qt.point(mouse.x, mouse.y)
                            let ps = barSurface.mapToItem(null, mouse.x, mouse.y)
                            pressScreenX = ps.x + (Config.barPosition === "right" ? Math.max(0, modelData.width - window.width) : 0)
                            pressScreenY = ps.y + (Config.barPosition === "bottom" ? Math.max(0, modelData.height - window.height) : 0)
                            screenScope.targetPos = ""
                            screenScope.barMoveActive = false
                        }
                        onPositionChanged: (mouse) => {
                            if (!(mouse.buttons & Qt.LeftButton)) return
                            let dx = mouse.x - pressPos.x
                            let dy = mouse.y - pressPos.y
                            if (!dragging && Math.abs(dx) + Math.abs(dy) > Config.scaledSize(6)) {
                                dragging = true
                            }
                            if (dragging) {
                                screenScope.barMoveActive = true
                                screenScope.targetPos = screenScope.nearestEdge(pressScreenX + dx, pressScreenY + dy)
                            }
                        }
                        onReleased: (mouse) => {
                            if (!dragging) return
                            dragging = false
                            screenScope.barMoveActive = false
                            screenScope.finishBarDrag()
                        }
                        onCanceled: {
                            dragging = false
                            screenScope.barMoveActive = false
                        }
                    }

                    Item {
                        id: contentStrip

                        width: window.vertical ? barSurface.height : barSurface.width
                        height: window.vertical ? barSurface.width : barSurface.height
                        anchors.centerIn: parent
                        rotation: Config.barRotation
                        transformOrigin: Item.Center

                        Component {
                            id: islandBg

                            Rectangle {
                                radius: Config.scaledBarRadius
                                color: Config.barBackgroundBg

                                Rectangle {
                                    visible: Config.barShadowsEnabled
                                    x: 0
                                    y: Config.shellShadowOffsetY
                                    width: parent.width
                                    height: parent.height
                                    radius: parent.radius
                                    color: Config.shellShadowColor
                                    opacity: 0.55
                                    z: -1
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: Config.innerBorderMargin
                                    radius: Math.max(0, parent.radius - Config.innerBorderMargin)
                                    color: "#00000000"
                                    border.color: Config.barBorderColor
                                    border.width: Config.barBordersEnabled ? 1 : 0
                                }
                            }
                        }

                        Loader {
                            id: leftIsland

                            visible: Config.barStyle === "islands"
                            sourceComponent: islandBg
                            x: 0
                            width: activeAppWidget.x + activeAppWidget.width
                            height: parent.height
                        }

                        Loader {
                            id: rightIsland

                            visible: Config.barStyle === "islands"
                            sourceComponent: islandBg
                            x: statusWidget.x
                            width: statusWidget.width
                            height: parent.height
                        }

                        Component.onCompleted: {
                            barSurface.leftIsland = leftIsland
                            barSurface.rightIsland = rightIsland
                        }

                        WorkspaceWidget {
                            id: workspaceWidget

                            embeddedInBar: true
                            appDrawer: root.appDrawer
                            monitorName: modelData.name
                            vertical: false
                            tooltip: barTooltip
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        ActiveAppWidget {
                            id: activeAppWidget

                            vertical: false
                            monitorName: modelData.name
                            tooltip: barTooltip
                            anchors.left: workspaceWidget.right
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StatusWidget {
                            id: statusWidget

                            embeddedInBar: true
                            calendarPopup: root.calendarPopup
                            controlCenterPopup: root.controlCenterPopup
                            brightnessPopup: root.brightnessPopup
                            wifiPopup: root.wifiPopup
                            bluetoothPopup: root.bluetoothPopup
                            audioPopup: root.audioPopup
                            batteryPopup: root.batteryPopup
                            notificationPopup: root.notificationPopup
                            trayMenuPopup: root.trayMenuPopup
                            keyboardLayoutPopup: root.keyboardLayoutPopup
                            settingsPopup: root.settingsPopup
                            powerPopup: root.powerPopup
                            systemPopup: root.systemPopup
                            mediaPopup: root.mediaPopup
                            osd: root.osd
                            vertical: false
                            tooltip: barTooltip
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                        }

                    }

                }

                BackgroundEffect.blurRegion: Region {
                    item: Config.barBlurEnabled && Config.barStyle === "solid" ? barSurface : null
                    radius: Math.round(barSurface.radius)

                    Region {
                        item: Config.barBlurEnabled && Config.barStyle === "islands" ? barSurface.leftIsland : null
                        radius: Math.round(barSurface.radius)
                    }

                    Region {
                        item: Config.barBlurEnabled && Config.barStyle === "islands" ? barSurface.rightIsland : null
                        radius: Math.round(barSurface.radius)
                    }
                }

            }

            PanelWindow {
                id: ghostWindow
                screen: modelData
                WlrLayershell.namespace: "quickshell-bar-move-ghost"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore
                visible: screenScope.barMoveActive
                color: "#00000000"
                mask: Region {}

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                Rectangle {
                    id: ghost
                    radius: Config.scaledBarRadius
                    color: Config.barBackgroundBg
                    opacity: 0.8
                    border.color: Qt.rgba(Config.themeAccent.r, Config.themeAccent.g, Config.themeAccent.b, 0.65)
                    border.width: 1

                    x: screenScope.targetPos === "right" ? window.screenWidth - Config.barHeight - Config.barMargin : Config.barMargin
                    y: screenScope.targetPos === "bottom" ? window.screenHeight - Config.barHeight - Config.scaledBarBottomMargin : Config.scaledBarTopMargin
                    width: (screenScope.targetPos === "left" || screenScope.targetPos === "right") ? Config.barHeight : window.screenWidth - Config.barMargin * 2
                    height: (screenScope.targetPos === "left" || screenScope.targetPos === "right") ? window.screenHeight - Config.scaledBarTopMargin - Config.scaledBarBottomMargin : Config.barHeight
                }
            }

        }

    }

}
