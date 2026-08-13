// SystemPopup.qml - detailed system monitor cards
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../Widgets"
import "../../Common"

PanelWindow {
  id: root

  property bool isOpen: false
  property int rightMargin: 16
  property int cpu: 0
  property int cpuTemp: 0
  property double load1: 0
  property string uptime: "0м"
  property int ramPct: 0
  property double ramUsed: 0
  property double ramTotal: 0
  property string rx: "0B/s"
  property string tx: "0B/s"
  property real rxBps: 0
  property real txBps: 0
  property int rootDisk: 0
  property int storageDisk: 0
  property bool storageExists: false
  property string uptimeSysmon: "UP 0D 00:00"
  readonly property string localizedUptimeSysmon: uptimeSysmon.indexOf("UP ") === 0 ? I18n.tr("UP") + uptimeSysmon.slice(2) : uptimeSysmon
  property double swapUsed: 0
  property bool hasGpu: false
  property int gpu: 0
  property int gpuTemp: 0
  property bool hasVram: false
  property double vramUsed: 0
  property double vramTotal: 0
  readonly property var dialKeys: hasGpu ? ["cpu", "gpu", "ram"] : ["cpu", "ram"]
  readonly property var cellKeys: hasVram ? ["net", "disk", "swap", "vram"] : ["net", "disk", "swap"]

  visible: isOpen || container.opacity > 0.01
  WlrLayershell.namespace: "quickshell-bar"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: 0
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  anchors { top: true; left: true; right: true; bottom: true }
  color: "#00000000"

  MouseArea { anchors.fill: parent; enabled: root.isOpen; onClicked: root.isOpen = false }
  onIsOpenChanged: if (isOpen) refresh()

  IpcHandler {
    target: "system"
    function toggle() { root.isOpen = !root.isOpen }
    function open() { root.isOpen = true }
    function close() { root.isOpen = false }
  }

  Process {
    id: sysProc
    command: [Qt.resolvedUrl("../../../core/hushctl").toString().replace("file://", ""), "sys"]
    running: false
    stdout: SplitParser { onRead: data => root.applyState(data) }
  }

  Timer { interval: 1000; running: root.isOpen; repeat: true; onTriggered: root.refresh() }

  function refresh() {
    sysProc.running = false
    sysProc.running = true
  }

  function applyState(data) {
    try {
      let res = JSON.parse(data)
      root.cpu = res.cpu || 0
      root.cpuTemp = res.cpu_temp || 0
      root.load1 = res.load1 || 0
      root.uptime = res.uptime || "0м"
      root.uptimeSysmon = res.uptime_sysmon || "UP 0D 00:00"
      root.ramPct = res.ram_pct || 0
      root.ramUsed = res.ram_used || 0
      root.ramTotal = res.ram_total || 0
      root.swapUsed = res.swap_used || 0
      root.rx = res.net_rx || "0B/s"
      root.tx = res.net_tx || "0B/s"
      root.rxBps = res.net_rx_bps || 0
      root.txBps = res.net_tx_bps || 0
      root.rootDisk = res.root_disk && res.root_disk.exists ? res.root_disk.percent : 0
      root.storageExists = !!(res.storage_disk && res.storage_disk.exists)
      root.storageDisk = root.storageExists ? res.storage_disk.percent : 0
      root.hasGpu = !!(res.gpu && res.gpu.has)
      root.gpu = root.hasGpu ? (res.gpu.load || 0) : 0
      root.gpuTemp = root.hasGpu ? (res.gpu.temp || 0) : 0
      root.hasVram = !!(res.gpu && res.gpu.has_vram)
      root.vramUsed = root.hasVram ? (res.gpu.vram_used || 0) : 0
      root.vramTotal = root.hasVram ? (res.gpu.vram_total || 0) : 0
    } catch(e) {}
  }

  function mib(value) {
    return Math.max(0, value / 1024 / 1024)
  }

  function speedText(value) {
    let mb = mib(value)
    if (mb >= 10) return mb.toFixed(0)
    if (mb >= 1) return mb.toFixed(1)
    return (value / 1024).toFixed(0) + "K"
  }

  function cellLabel(key) {
    if (key === "net") return "СЕТЬ · МБ/С"
    if (key === "disk") return "ДИСК · %"
    if (key === "swap") return "SWAP · ГБ"
    return "VRAM · ГБ"
  }

  Rectangle {
    id: container
    width: 390
    implicitHeight: content.implicitHeight + 30
    anchors.right: parent.right
    anchors.rightMargin: root.rightMargin
    y: root.isOpen ? Config.popupTopGap : -12
    opacity: root.isOpen ? 1.0 : 0.0
    radius: Config.overlayRadius
    color: Config.glassBg

    Rectangle {
      visible: Config.shellShadowsEnabled
      x: 0
      y: Config.shellShadowOffsetY
      width: parent.width
      height: parent.height
      radius: parent.radius
      color: Config.shellShadowColor
      opacity: 0.55
      z: -1
    }

    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea { anchors.fill: parent; onClicked: mouse => { mouse.accepted = true } }
    Rectangle { anchors.fill: parent; anchors.margins: Config.innerBorderMargin; radius: Config.overlayRadius - 2; color: "#00000000"; border.color: Config.borderColor; border.width: Config.shellBordersEnabled ? 1 : 0 }

    Column {
      id: content
      width: parent.width - 32
      anchors.top: parent.top
      anchors.topMargin: 15
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 0

      Item {
        width: parent.width
        height: 24
        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 9
          Text { text: Config.iconCpu; color: Config.textWhite; font.pixelSize: Config.fontSizeIconMedium; font.family: Config.fontIcon; anchors.verticalCenter: parent.verticalCenter }
          Text { text: "СИСТЕМА"; color: Config.textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 1.8; anchors.verticalCenter: parent.verticalCenter }
        }
        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: root.localizedUptimeSysmon; color: Config.textMuted; font.pixelSize: 10; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 1.1 }
      }

      Item { width: 1; height: 16 }

      Item {
        width: parent.width
        height: 110
        Repeater {
          model: root.dialKeys
          SystemDial {
            required property int index
            required property var modelData
            readonly property string key: modelData
            readonly property int pct: key === "cpu" ? root.cpu : (key === "gpu" ? root.gpu : root.ramPct)
            x: root.dialKeys.length > 1 ? index * (parent.width - width) / (root.dialKeys.length - 1) : (parent.width - width) / 2
            value: pct
            primary: key === "ram" ? root.ramUsed.toFixed(1) : pct.toString()
            unit: key === "ram" ? "" : "%"
            label: key === "cpu" ? I18n.tr("CPU") : (key === "gpu" ? I18n.tr("GPU") : I18n.tr("RAM"))
            sub: key === "cpu" ? (root.cpuTemp > 0 ? root.cpuTemp + "°" : "") : (key === "gpu" ? (root.gpuTemp > 0 ? root.gpuTemp + "°" : "") : "/ " + root.ramTotal.toFixed(0) + " ГБ")
          }
        }
      }

      Item { width: 1; height: 18 }
      Rectangle { width: parent.width; height: 1; color: Config.separatorColor; opacity: 0.45 }
      Item { width: 1; height: 13 }

      Item {
        width: parent.width
        height: 34
        Repeater {
          model: root.cellKeys
          Item {
            required property int index
            required property var modelData
            readonly property string key: modelData
            width: parent.width / root.cellKeys.length
            height: parent.height
            x: index * width

            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 1; visible: index > 0; color: Config.separatorColor; opacity: 0.35 }

            Column {
              anchors.centerIn: parent
              spacing: 6
              Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.cellLabel(key); color: Config.textMuted; font.pixelSize: 8; font.weight: Font.Bold; font.family: Config.fontSans; font.letterSpacing: 0.8 }
              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                visible: key === "net"
                Text { text: "↓" + root.mib(root.rxBps).toFixed(root.mib(root.rxBps) >= 10 ? 0 : 1); color: Config.textWhite; font.pixelSize: 13; font.weight: Font.ExtraBold; font.family: Config.fontSans }
                Text { text: "↑" + root.mib(root.txBps).toFixed(root.mib(root.txBps) >= 10 ? 0 : 1); color: Config.accentBlue; font.pixelSize: 13; font.weight: Font.ExtraBold; font.family: Config.fontSans }
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: key !== "net"
                text: key === "disk" ? root.rootDisk.toString() : (key === "swap" ? root.swapUsed.toFixed(1) : root.vramUsed.toFixed(1) + " / " + root.vramTotal.toFixed(0))
                color: Config.textWhite
                font.pixelSize: 13
                font.weight: Font.ExtraBold
                font.family: Config.fontSans
              }
            }
          }
        }
      }
    }
  }
}
