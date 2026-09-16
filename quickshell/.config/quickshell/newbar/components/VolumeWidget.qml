import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"

Item {
    id: root

    required property var barWindow

    implicitHeight: Theme.capsuleHeight
    implicitWidth: volCapsule.implicitWidth

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0.0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property int volumePercent: Math.round(volume * 100)

    readonly property string volumeIcon: {
        if (muted) return "󰖁";
        if (volumePercent >= 60) return "󰕾";
        if (volumePercent >= 30) return "󰖀";
        return "󰕿";
    }

    function toggleMute() {
        if (sink && sink.audio) {
            sink.audio.muted = !sink.audio.muted;
        }
    }

    function changeVolume(delta) {
        if (sink && sink.audio) {
            var newVol = Math.max(0.0, Math.min(1.5, sink.audio.volume + delta));
            sink.audio.volume = newVol;
            if (sink.audio.muted && delta > 0) {
                sink.audio.muted = false;
            }
        }
    }

    Rectangle {
        id: volCapsule
        anchors.fill: parent
        radius: Theme.radiusPill
        color: volMouse.containsMouse ? Theme.bgLight : "transparent"

        implicitWidth: volRow.implicitWidth + 12
        implicitHeight: Theme.capsuleHeight

        RowLayout {
            id: volRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.volumeIcon
                color: root.muted ? Theme.red : Theme.aqua
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.iconSizeSm
                }
            }

            Text {
                text: root.volumePercent + "%"
                color: root.muted ? Theme.fgDark : Theme.fg
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.fontSizeSm
                    weight: Font.Medium
                }
            }
        }

        MouseArea {
            id: volMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    root.toggleMute();
                } else {
                    Quickshell.execDetached(["pavucontrol"]);
                }
            }

            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) {
                    root.changeVolume(0.05);
                } else if (wheel.angleDelta.y < 0) {
                    root.changeVolume(-0.05);
                }
            }
        }
    }
}
