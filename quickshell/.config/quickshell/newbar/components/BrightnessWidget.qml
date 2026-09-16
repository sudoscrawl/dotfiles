import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    required property var barWindow

    implicitHeight: Theme.capsuleHeight
    implicitWidth: brightCapsule.implicitWidth

    property int brightnessPercent: 50

    readonly property string brightIcon: {
        if (brightnessPercent >= 70) return "󰃠";
        if (brightnessPercent >= 35) return "󰃟";
        return "󰃞";
    }

    Process {
        id: brightProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onDataChanged: {
                try {
                    var parts = text.trim().split(",");
                    if (parts.length >= 4) {
                        var p = parseInt(parts[3].replace("%", ""));
                        if (!isNaN(p)) root.brightnessPercent = p;
                    }
                } catch(e) {}
            }
        }
    }

    function setBrightness(percent) {
        var p = Math.max(5, Math.min(100, Math.round(percent)));
        root.brightnessPercent = p;
        Quickshell.execDetached(["brightnessctl", "set", p + "%"]);
    }

    function changeBrightness(delta) {
        var newP = Math.max(5, Math.min(100, root.brightnessPercent + delta));
        root.brightnessPercent = newP;
        Quickshell.execDetached(["brightnessctl", "set", newP + "%"]);
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: brightProc.running = true
    }

    Rectangle {
        id: brightCapsule
        anchors.fill: parent
        radius: Theme.radiusPill
        color: brightMouse.containsMouse ? Theme.bgLight : "transparent"

        implicitWidth: brightRow.implicitWidth + 12
        implicitHeight: Theme.capsuleHeight

        RowLayout {
            id: brightRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.brightIcon
                color: Theme.yellow
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.iconSizeSm
                }
            }

            Text {
                text: root.brightnessPercent + "%"
                color: Theme.fg
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.fontSizeSm
                    weight: Font.Medium
                }
            }
        }

        MouseArea {
            id: brightMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) {
                    root.changeBrightness(5);
                } else if (wheel.angleDelta.y < 0) {
                    root.changeBrightness(-5);
                }
            }
        }
    }
}
