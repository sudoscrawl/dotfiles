import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    required property var barWindow

    implicitHeight: Theme.capsuleHeight
    implicitWidth: powerCapsule.implicitWidth

    // Power icon capsule on the status bar
    Rectangle {
        id: powerCapsule
        anchors.fill: parent
        radius: Theme.radiusPill
        color: powerMouse.containsMouse ? Theme.bgLight : Theme.bgAlt
        border {
            width: 1
            color: powerPopup.visible ? Theme.red : (powerMouse.containsMouse ? Theme.borderHover : Theme.border)
        }

        implicitWidth: 32
        implicitHeight: Theme.capsuleHeight

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            anchors.centerIn: parent
            text: "󰐥"
            color: powerMouse.containsMouse ? Theme.red : Theme.fg
            font {
                family: Theme.fontMono
                pixelSize: Theme.iconSizeMd
            }
        }

        MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                powerPopup.visible = !powerPopup.visible;
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // POWER SESSION POPUP
    // ─────────────────────────────────────────────────────────────
    PopupWindow {
        id: powerPopup

        anchor.window: root.barWindow
        anchor.rect.x: Math.round(root.mapToItem(null, 0, 0).x + root.width - width)
        anchor.rect.y: root.barWindow.height + 2

        implicitWidth: 240
        implicitHeight: 280
        color: "transparent"
        visible: false
        grabFocus: true

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusPopup
            color: Theme.bgCard
            border {
                width: 1
                color: Theme.borderFocus
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Text {
                    text: "󰐥 Power Session"
                    color: Theme.fgBright
                    font {
                        family: Theme.fontMono
                        pixelSize: Theme.fontSizeMd
                        weight: Font.Bold
                    }
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderSubtle
                }

                // Power option buttons
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Lock
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: lockMouse.containsMouse ? Theme.bgLight : Theme.bgAlt
                        border { width: 1; color: lockMouse.containsMouse ? Theme.borderHover : Theme.border }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text { text: "󰌾"; color: Theme.yellow; font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm } }
                            Text { text: "Lock Screen"; color: Theme.fg; font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm } Layout.fillWidth: true }
                        }

                        MouseArea {
                            id: lockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerPopup.visible = false;
                                Quickshell.execDetached(["hyprlock"]);
                            }
                        }
                    }

                    // Suspend
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: suspMouse.containsMouse ? Theme.bgLight : Theme.bgAlt
                        border { width: 1; color: suspMouse.containsMouse ? Theme.borderHover : Theme.border }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text { text: "󰤄"; color: Theme.aqua; font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm } }
                            Text { text: "Suspend"; color: Theme.fg; font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm } Layout.fillWidth: true }
                        }

                        MouseArea {
                            id: suspMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerPopup.visible = false;
                                Quickshell.execDetached(["systemctl", "suspend"]);
                            }
                        }
                    }

                    // Logout
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: logoutMouse.containsMouse ? Theme.bgLight : Theme.bgAlt
                        border { width: 1; color: logoutMouse.containsMouse ? Theme.borderHover : Theme.border }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text { text: "󰍃"; color: Theme.orange; font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm } }
                            Text { text: "Logout"; color: Theme.fg; font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm } Layout.fillWidth: true }
                        }

                        MouseArea {
                            id: logoutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerPopup.visible = false;
                                const sessionId = Quickshell.env("XDG_SESSION_ID");
                                if (sessionId) {
                                    Quickshell.execDetached(["loginctl", "kill-session", sessionId]);
                                } else {
                                    Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER") || ""]);
                                }
                            }
                        }
                    }

                    // Reboot
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: rebootMouse.containsMouse ? Theme.bgLight : Theme.bgAlt
                        border { width: 1; color: rebootMouse.containsMouse ? Theme.borderHover : Theme.border }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text { text: "󰑐"; color: Theme.yellow; font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm } }
                            Text { text: "Reboot"; color: Theme.fg; font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm } Layout.fillWidth: true }
                        }

                        MouseArea {
                            id: rebootMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerPopup.visible = false;
                                Quickshell.execDetached(["systemctl", "reboot"]);
                            }
                        }
                    }

                    // Shutdown
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: poweroffMouse.containsMouse ? Theme.redDim : Theme.bgAlt
                        border { width: 1; color: poweroffMouse.containsMouse ? Theme.red : Theme.border }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text { text: "󰐥"; color: Theme.red; font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm } }
                            Text { text: "Power Off"; color: poweroffMouse.containsMouse ? Theme.fgBright : Theme.fg; font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm; weight: Font.Bold } Layout.fillWidth: true }
                        }

                        MouseArea {
                            id: poweroffMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerPopup.visible = false;
                                Quickshell.execDetached(["systemctl", "poweroff"]);
                            }
                        }
                    }
                }
            }
        }
    }
}
