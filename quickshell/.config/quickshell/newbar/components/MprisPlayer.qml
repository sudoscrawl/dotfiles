import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

Rectangle {
    id: root

    // Find the current active or first available player
    readonly property var activePlayer: {
        if (!Mpris.players || !Mpris.players.values || Mpris.players.values.length === 0) return null;
        // Priority 1: playing player
        for (var i = 0; i < Mpris.players.values.length; i++) {
            var p = Mpris.players.values[i];
            if (p && p.isPlaying) return p;
        }
        // Priority 2: player with a track title
        for (var j = 0; j < Mpris.players.values.length; j++) {
            var q = Mpris.players.values[j];
            if (q && q.trackTitle && q.trackTitle.trim() !== "") return q;
        }
        return Mpris.players.values[0];
    }

    readonly property bool hasMedia: activePlayer !== null && activePlayer.trackTitle && activePlayer.trackTitle.trim() !== ""

    visible: hasMedia
    implicitHeight: Theme.capsuleHeight
    implicitWidth: hasMedia ? Math.min(220, mprisRow.implicitWidth + 12) : 0
    radius: Theme.radiusPill
    color: "transparent"

    Behavior on implicitWidth {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: mprisRow
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 6
            rightMargin: 6
        }
        spacing: 4

        // Media Icon
        Text {
            text: (root.activePlayer && root.activePlayer.identity && root.activePlayer.identity.toLowerCase().indexOf("spotify") !== -1) ? "󰓇" : "󰎆"
            color: (root.activePlayer && root.activePlayer.isPlaying) ? Theme.green : Theme.fgMuted
            font {
                family: Theme.fontMono
                pixelSize: Theme.iconSizeSm
            }
        }

        // Track & Artist text
        Text {
            Layout.fillWidth: true
            text: {
                if (!root.activePlayer) return "";
                var title = root.activePlayer.trackTitle || "";
                var artist = root.activePlayer.trackArtist || "";
                if (artist !== "") return title + " • " + artist;
                return title;
            }
            color: Theme.fg
            elide: Text.ElideRight
            font {
                family: Theme.fontMono
                pixelSize: Theme.fontSizeSm
                weight: Font.Medium
            }
        }

        // Controls
        RowLayout {
            spacing: 2

            // Previous
            Text {
                text: "󰒮"
                color: prevMouse.containsMouse ? Theme.fgBright : Theme.fgMuted
                font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activePlayer && root.activePlayer.canGoPrevious) {
                            root.activePlayer.previous();
                        }
                    }
                }
            }

            // Play / Pause
            Text {
                text: (root.activePlayer && root.activePlayer.isPlaying) ? "󰏤" : "󰐊"
                color: playMouse.containsMouse ? Theme.yellow : Theme.fg
                font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activePlayer && root.activePlayer.canTogglePlaying) {
                            root.activePlayer.togglePlaying();
                        }
                    }
                }
            }

            // Next
            Text {
                text: "󰒭"
                color: nextMouse.containsMouse ? Theme.fgBright : Theme.fgMuted
                font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activePlayer && root.activePlayer.canGoNext) {
                            root.activePlayer.next();
                        }
                    }
                }
            }
        }
    }
}
