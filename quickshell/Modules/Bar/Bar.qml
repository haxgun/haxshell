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
            required property var modelData

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

                    // Right-click on empty bar area opens settings near the cursor.
                    // Placed below widgets so tray icons handle their own right-click first.
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: (mouse) => {
                            root.closeBarFlyouts();
                            if (!root.settingsPopup)
                                return ;

                            let gap = 16;
                            let screenW = window.screenWidth;
                            let popupW = Config.scaledSize(620);
                            let windowOffsetX = window.posRight ? (screenW - window.width) : 0;
                            let cursorX = windowOffsetX + barSurface.x + mouse.x;
                            root.settingsPopup.rightMargin = Math.max(gap, Math.min(screenW - popupW - gap, screenW - popupW / 2 - cursorX));
                            root.settingsPopup.isOpen = true;
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

        }

    }

}
