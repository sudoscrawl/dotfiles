import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../theme"

Item {
    id: root

    required property var barWindow

    implicitHeight: Theme.capsuleHeight
    implicitWidth: batCapsule.implicitWidth

    readonly property var dev: UPower.displayDevice
    readonly property int percentage: dev ? Math.round(dev.percentage * 100) : 100
    readonly property bool isCharging: dev ? (dev.state === UPowerDeviceState.Charging) : false
    readonly property bool isLow: percentage <= 20 && !isCharging

    readonly property string batteryIcon: {
        if (isCharging) return "󰂄";
        if (percentage >= 90) return "󰁹";
        if (percentage >= 70) return "󰂂";
        if (percentage >= 50) return "󰁿";
        if (percentage >= 30) return "󰁾";
        if (percentage >= 15) return "󰁼";
        return "󰂎";
    }

    Rectangle {
        id: batCapsule
        anchors.fill: parent
        radius: Theme.radiusPill
        color: batMouse.containsMouse ? Theme.bgLight : "transparent"

        implicitWidth: batRow.implicitWidth + 12
        implicitHeight: Theme.capsuleHeight

        RowLayout {
            id: batRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.batteryIcon
                color: root.isCharging ? Theme.green : (root.isLow ? Theme.red : Theme.fg)
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.iconSizeSm
                }
            }

            Text {
                text: root.percentage + "%"
                color: root.isLow ? Theme.red : Theme.fg
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.fontSizeSm
                    weight: Font.Medium
                }
            }
        }

        MouseArea {
            id: batMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
