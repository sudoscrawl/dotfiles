import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root

    property int count: 0
    property bool dnd: false

    implicitHeight: Theme.capsuleHeight
    implicitWidth: notifRow.implicitWidth + 10
    radius: Theme.radiusPill
    color: notifMouse.containsMouse ? Theme.bgLight : "transparent"

    Process {
        id: notifProc
        command: ["bash", "-c", "echo \"$(swaync-client -c 2>/dev/null)|$(swaync-client -D 2>/dev/null)\""]
        running: true
        stdout: StdioCollector {
            onDataChanged: {
                try {
                    var parts = text.trim().split("|");
                    if (parts.length >= 2) {
                        root.count = parseInt(parts[0]) || 0;
                        root.dnd = (parts[1].trim() === "true");
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: notifProc.running = true
    }

    RowLayout {
        id: notifRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: root.dnd ? "󰂛" : (root.count > 0 ? "󰂚" : "󰂜")
            color: root.dnd ? Theme.fgDark : (root.count > 0 ? Theme.yellow : Theme.fg)
            font {
                family: Theme.fontMono
                pixelSize: Theme.iconSizeSm
            }
        }

        Text {
            visible: root.count > 0
            text: root.count.toString()
            color: Theme.yellow
            font {
                family: Theme.fontMono
                pixelSize: Theme.fontSizeSm
                weight: Font.Bold
            }
        }
    }

    MouseArea {
        id: notifMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["swaync-client", "-d", "-sw"]);
            } else {
                Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
            }
            notifProc.running = true;
        }
    }
}
