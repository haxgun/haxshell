// Time.qml - Standalone date and time display widget
pragma Singleton

import Quickshell
import QtQuick
import "../../Common"

Singleton {
  id: root
  // an expression can be broken across multiple lines using {}
  readonly property string date: {
    Config.formatShortDateRu(clock.date)
  }
  readonly property string time: {
    Config.formatTime24(clock.date)
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
