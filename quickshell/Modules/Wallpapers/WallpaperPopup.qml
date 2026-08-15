// WallpaperPopup.qml - Wallpaper selector overlay
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property string thumbnail: ""
  property string wallName: "Нет обоев"
  property int currentIndex: 0
  property var palette: []
  readonly property string hushctl: Config.hushctl

  visible: isOpen || container.opacity > 0.01

  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"
  BackgroundEffect.blurRegion: Region {
    item: Config.popupBlurEnabled ? container : null
    radius: Math.round(container.radius)
  }

  MouseArea { anchors.fill: parent; enabled: root.isOpen; onClicked: root.isOpen = false }

  IpcHandler {
    target: "wallpaper"
    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  ListModel { id: wallpapersModel }

  Process {
    id: wallpaperProc
    command: [root.hushctl, "wallpaper", "get", Config.wallpaperDir]
    running: true
    stdout: SplitParser { onRead: data => root.applyState(data) }
  }

  Connections {
    target: Config
    function onWallpaperDirChanged() { root.refresh() }
  }

  onIsOpenChanged: if (isOpen) refresh()

  function refresh() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.hushctl, "wallpaper", "get", Config.wallpaperDir, Config.wallpaperPaletteScheme]
    wallpaperProc.running = true
  }

  function nextWallpaper() {
    wallpaperProc.running = false
    wallpaperProc.command = [root.hushctl, "wallpaper", "next", Config.wallpaperDir, Config.wallpaperPaletteScheme]
    wallpaperProc.running = true
  }

  function setWallpaper(index) {
    wallpaperProc.running = false
    wallpaperProc.command = [root.hushctl, "wallpaper", "set", index.toString(), Config.wallpaperDir, Config.wallpaperPaletteScheme]
    wallpaperProc.running = true
  }

  function applyState(data) {
    try {
      let res = JSON.parse(data)
      root.thumbnail = res.thumbnail || ""
      root.wallName = res.name || "Нет обоев"
      root.currentIndex = res.index || 0
      root.palette = res.palette || []
      if (root.palette.length > 0) {
        Config.applyDynamicPalette(root.palette)
        SettingsStore.setValue("dynamicAccent", Config.dynamicAccent)
        SettingsStore.setValue("dynamicPalette", JSON.stringify(Config.dynamicPalette))
      }
      wallpapersModel.clear()
      let items = res.items || []
      for (let i = 0; i < items.length; i++) wallpapersModel.append(items[i])
    } catch(e) {}
  }

  Rectangle {
    id: container
    width: 340
    implicitHeight: columnLayout.implicitHeight + 28
    anchors.left: Config.popupsAtLeft ? parent.left : undefined
    anchors.leftMargin: Config.popupsAtLeft ? Config.popupGap : undefined
    anchors.right: Config.popupsAtLeft ? undefined : parent.right
    anchors.rightMargin: 16
    y: root.isOpen ? (Config.popupsAtBottom ? parent.height - height - Config.popupGap : Config.popupGap) : (Config.popupsAtBottom ? parent.height + 12 : -12)
    opacity: root.isOpen ? 1.0 : 0.0
    color: Config.popupGlassBg
    radius: Config.overlayRadius

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.popupBorderColor; border.width: Config.popupBordersEnabled ? 1 : 0 }

    Column {
      id: columnLayout
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 12

      Rectangle {
        width: parent.width
        height: 120
        radius: Config.cardRadius
        clip: true
        color: Config.controlIdleBg

        Image { anchors.fill: parent; source: root.thumbnail; fillMode: Image.PreserveAspectCrop; visible: root.thumbnail.length > 0; asynchronous: true }
        Rectangle { anchors.fill: parent; color: "#50000000" }
        Text { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 12; text: root.wallName; color: Config.textWhite; font.pixelSize: Config.fontSizeNormal; font.weight: Font.Bold; font.family: Config.fontSans; elide: Text.ElideRight }
      }

      Row {
        width: parent.width
        height: 18
        spacing: 6
        visible: root.palette.length > 0

        Repeater {
          model: root.palette
          Rectangle {
            required property string modelData
            width: (parent.width - 30) / 6
            height: 18
            radius: 6
            color: modelData
            border.color: Config.borderColor
            border.width: 1
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 32
        radius: 9
        color: nextMouse.containsMouse ? Config.activeHoverBg : Config.selectedBg
        border.color: Config.activeBorderColor
        border.width: 1
        Text { anchors.centerIn: parent; text: "Следующие обои"; color: Config.textWhite; font.pixelSize: Config.fontSizeSmall; font.weight: Font.Bold; font.family: Config.fontSans }
        MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.nextWallpaper() }
      }

      ListView {
        width: parent.width
        height: Math.min(230, contentHeight)
        clip: true
        spacing: 6
        model: wallpapersModel

        delegate: Rectangle {
          required property int wallIndex
          required property string name
          required property string thumbnail
          width: ListView.view.width
          height: 42
          radius: Config.cardRadius
          color: wallItemMouse.containsMouse || wallIndex === root.currentIndex ? Config.hoverBg : "#00000000"
          border.color: wallIndex === root.currentIndex ? Config.activeBorderColor : "#00000000"
          border.width: wallIndex === root.currentIndex ? 1 : 0
          Image { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; width: 34; height: 26; source: thumbnail; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: thumbnail.length > 0; clip: true }
          Text { anchors.fill: parent; anchors.leftMargin: 50; anchors.rightMargin: 12; verticalAlignment: Text.AlignVCenter; text: name; color: wallIndex === root.currentIndex ? Config.textWhite : Config.textPrimary; font.pixelSize: Config.fontSizeSmall; font.weight: wallIndex === root.currentIndex ? Font.Bold : Font.Medium; font.family: Config.fontSans; elide: Text.ElideRight }
          MouseArea { id: wallItemMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setWallpaper(wallIndex) }
        }
      }
    }
  }
}
