import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    required property var barWindow

    implicitHeight: Theme.capsuleHeight
    implicitWidth: statsCapsule.implicitWidth

    property int cpuPercent: 0
    property int memPercent: 0
    property string memUsedGb: "0.0"
    property string memTotalGb: "0.0"
    property string diskUsed: "0"
    property string diskTotal: "0"
    property string diskPercent: "0%"

    Process {
        id: statsProc
        command: ["bash", "-c", "cpu=$(top -bn1 | grep 'Cpu(s)' | awk '{printf(\"%.0f\", $2 + $4)}'); mem=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf(\"%.0f:%.1f:%.1f\", (t-a)/t*100, (t-a)/1048576, t/1048576)}' /proc/meminfo); disk=$(df -h / | awk 'NR==2 {printf(\"%s:%s:%s\", $3, $2, $5)}'); echo \"$cpu|$mem|$disk\""]
        running: true
        stdout: StdioCollector {
            onDataChanged: {
                try {
                    var parts = text.trim().split("|");
                    if (parts.length >= 3) {
                        root.cpuPercent = parseInt(parts[0]) || 0;
                        var m = parts[1].split(":");
                        if (m.length >= 3) {
                            root.memPercent = parseInt(m[0]) || 0;
                            root.memUsedGb = m[1];
                            root.memTotalGb = m[2];
                        }
                        var d = parts[2].split(":");
                        if (d.length >= 3) {
                            root.diskUsed = d[0];
                            root.diskTotal = d[1];
                            root.diskPercent = d[2];
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: statsProc.running = true
    }

    Rectangle {
        id: statsCapsule
        anchors.fill: parent
        radius: Theme.radiusPill
        color: statsMouse.containsMouse ? Theme.bgLight : "transparent"

        implicitWidth: statsRow.implicitWidth + 12
        implicitHeight: Theme.capsuleHeight

        RowLayout {
            id: statsRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: root.cpuPercent + "%"
                color: root.cpuPercent > 80 ? Theme.red : (root.cpuPercent > 50 ? Theme.yellow : Theme.fg)
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.fontSizeSm
                    weight: Font.Medium
                }
            }

            Text {
                text: root.memUsedGb + "G"
                color: root.memPercent > 80 ? Theme.red : (root.memPercent > 60 ? Theme.yellow : Theme.fg)
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.fontSizeSm
                    weight: Font.Medium
                }
            }
        }

        MouseArea {
            id: statsMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.execDetached(["kitty", "-e", "btop"]);
            }
        }
    }
}
