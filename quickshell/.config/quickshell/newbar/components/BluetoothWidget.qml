import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../theme"

Item {
    id: root

    required property var barWindow

    implicitHeight: Theme.capsuleHeight
    implicitWidth: btCapsule.implicitWidth

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool isEnabled: adapter ? adapter.enabled : false

    readonly property int connectedCount: {
        var count = 0;
        if (Bluetooth.devices && Bluetooth.devices.values) {
            for (var i = 0; i < Bluetooth.devices.values.length; i++) {
                var d = Bluetooth.devices.values[i];
                if (d && d.connected) count++;
            }
        }
        return count;
    }

    readonly property string btIcon: {
        if (!isEnabled) return "󰂲";
        if (connectedCount > 0) return "󰂯";
        return "󰂴";
    }

    // ─────────────────────────────────────────────────────────────
    // BLUETOOTHCTL PROCESSES
    // ─────────────────────────────────────────────────────────────
    Process {
        id: btPowerOn
        command: ["bluetoothctl", "power", "on"]
        running: false
    }

    Process {
        id: btPowerOff
        command: ["bluetoothctl", "power", "off"]
        running: false
    }

    Process {
        id: btScanOn
        command: ["bluetoothctl", "scan", "on"]
        running: false
    }

    Process {
        id: btScanOff
        command: ["bluetoothctl", "scan", "off"]
        running: false
    }

    // Per-device connect/disconnect processes
    Process {
        id: btConnectProc
        property string targetAddress: ""
        command: ["bluetoothctl", "connect", targetAddress]
        running: false
    }

    Process {
        id: btDisconnectProc
        property string targetAddress: ""
        command: ["bluetoothctl", "disconnect", targetAddress]
        running: false
    }

    // Stop scanning when popup closes
    onIsEnabledChanged: {
        if (!isEnabled && btPopup.visible) {
            btScanOff.running = true;
        }
    }

    function toggleBluetooth() {
        if (root.isEnabled) {
            btScanOff.running = true;
            btPowerOff.running = true;
            // Also update via API for immediate UI feedback
            if (root.adapter) root.adapter.enabled = false;
        } else {
            btPowerOn.running = true;
            if (root.adapter) root.adapter.enabled = true;
        }
    }

    function openPopup() {
        btPopup.visible = true;
        if (root.isEnabled) {
            btScanOn.running = true;
        }
    }

    function closePopup() {
        btPopup.visible = false;
        btScanOff.running = true;
    }

    // ─────────────────────────────────────────────────────────────
    // STATUS BAR CAPSULE
    // ─────────────────────────────────────────────────────────────
    Rectangle {
        id: btCapsule
        anchors.fill: parent
        radius: Theme.radiusPill
        color: btMouse.containsMouse ? Theme.bgLight : "transparent"
        
        implicitWidth: 28
        implicitHeight: Theme.capsuleHeight

        RowLayout {
            id: btRow
            anchors.centerIn: parent
            spacing: 0

            Text {
                text: root.btIcon
                color: root.connectedCount > 0 ? Theme.blue : (root.isEnabled ? Theme.fg : Theme.fgMuted)
                font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: btMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btPopup.visible ? root.closePopup() : root.openPopup()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // BLUETOOTH POPUP
    // ─────────────────────────────────────────────────────────────
    PopupWindow {
        id: btPopup

        anchor.window: root.barWindow
        anchor.rect.x: Math.round(Math.max(12, Math.min(
            root.barWindow.width - width - 12,
            root.mapToItem(null, 0, 0).x + root.width / 2 - width / 2
        )))
        anchor.rect.y: root.barWindow.height + 2

        implicitWidth: 280
        implicitHeight: 300
        color: "transparent"
        visible: false
        grabFocus: true

        onVisibleChanged: {
            if (!visible) {
                btScanOff.running = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusPopup
            color: Theme.bgCard
            border { width: 1; color: Theme.borderFocus }

            // Inner rim
            Rectangle {
                anchors { fill: parent; margins: 1 }
                radius: Theme.radiusPopup - 1
                color: "transparent"
                border { width: 1; color: "#15d5c6a5" }
            }

            // ── Header ─────────────────────────────────────────────
            RowLayout {
                id: btHeader
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
                height: 44
                spacing: 10

                // Icon badge
                Rectangle {
                    width: 34; height: 34
                    radius: 10
                    color: root.isEnabled ? "#1a83a598" : Theme.bgLight
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰂯"
                        color: root.isEnabled ? Theme.blue : Theme.fgMuted
                        font { family: Theme.fontMono; pixelSize: Theme.iconSizeMd }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    Text {
                        text: "Bluetooth"
                        color: Theme.fgBright
                        font { family: Theme.fontMono; pixelSize: Theme.fontSizeMd; weight: Font.Bold }
                    }
                    Text {
                        text: root.isEnabled
                            ? (root.connectedCount > 0
                                ? root.connectedCount + (root.connectedCount > 1 ? " devices" : " device") + " connected"
                                : "Scanning for devices…")
                            : "Disabled"
                        color: root.isEnabled ? Theme.fgMuted : Theme.fgDark
                        font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Custom pill toggle
                Rectangle {
                    width: 44; height: 24; radius: 12
                    color: root.isEnabled ? Theme.blue : Theme.bgLight
                    border { width: 1; color: root.isEnabled ? "transparent" : Theme.border }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Rectangle {
                        width: 18; height: 18; radius: 9
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.isEnabled ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleBluetooth()
                    }
                }
            }

            // Divider
            Rectangle {
                id: btDivider
                anchors { top: btHeader.bottom; left: parent.left; right: parent.right; topMargin: 4; leftMargin: 16; rightMargin: 16 }
                height: 1
                color: Theme.borderSubtle
            }

            // ── Device list ─────────────────────────────────────────
            ListView {
                id: deviceList
                anchors {
                    top: btDivider.bottom; bottom: parent.bottom
                    left: parent.left; right: parent.right
                    topMargin: 8; bottomMargin: 8; leftMargin: 8; rightMargin: 8
                }
                clip: true
                model: Bluetooth.devices
                spacing: 3

                // Empty / disabled placeholder
                Item {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 80
                    visible: !root.isEnabled || deviceList.count === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isEnabled ? "󰂯" : "󰂲"
                            color: Theme.fgSubdued
                            font { family: Theme.fontMono; pixelSize: Theme.iconSizeLg }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isEnabled ? "No paired devices" : "Bluetooth is off"
                            color: Theme.fgDark
                            font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                        }
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 48
                    radius: Theme.radiusInner
                    color: rowHover.containsMouse ? Theme.bgSubtle : "transparent"
                    border { width: 1; color: modelData.connected ? "#2083a598" : "transparent" }
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 10

                        // Device type icon
                        Text {
                            text: {
                                var ic = modelData.icon || "";
                                if (ic.indexOf("headphone") >= 0 || ic.indexOf("headset") >= 0) return "󰋋";
                                if (ic.indexOf("audio") >= 0 || ic.indexOf("speaker") >= 0) return "󰓃";
                                if (ic.indexOf("input-keyboard") >= 0) return "󰌌";
                                if (ic.indexOf("input-mouse") >= 0) return "󰍽";
                                if (ic.indexOf("input-gaming") >= 0) return "󰊗";
                                if (ic.indexOf("phone") >= 0) return "󰏲";
                                return "󰂯";
                            }
                            color: modelData.connected ? Theme.blue : Theme.fgMuted
                            font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Name + status
                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true

                            Text {
                                text: modelData.name || modelData.deviceName || "Unknown Device"
                                color: modelData.connected ? Theme.fgBright : Theme.fg
                                font {
                                    family: Theme.fontMono
                                    pixelSize: Theme.fontSizeSm
                                    weight: modelData.connected ? Font.Bold : Font.Normal
                                }
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                text: modelData.connected ? "Connected" : "Not connected"
                                color: modelData.connected ? Theme.blue : Theme.fgDark
                                font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        // Connect / Disconnect button
                        Rectangle {
                            implicitWidth: btnText.implicitWidth + 16
                            height: 22; radius: 6
                            color: btnHover.containsMouse
                                ? (modelData.connected ? "#33fb4934" : "#2283a598")
                                : (modelData.connected ? "#1afb4934" : "#1283a598")
                            border { width: 1; color: modelData.connected ? "#44fb4934" : "#4483a598" }
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                id: btnText
                                anchors.centerIn: parent
                                text: modelData.connected ? "Disconnect" : "Connect"
                                color: modelData.connected ? Theme.red : Theme.blue
                                font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs; weight: Font.Medium }
                            }

                            MouseArea {
                                id: btnHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var addr = modelData.address || "";
                                    if (modelData.connected) {
                                        if (addr !== "") {
                                            btDisconnectProc.targetAddress = addr;
                                            btDisconnectProc.running = true;
                                        } else {
                                            modelData.connected = false;
                                        }
                                    } else {
                                        if (addr !== "") {
                                            btConnectProc.targetAddress = addr;
                                            btConnectProc.running = true;
                                        } else {
                                            modelData.connected = true;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
    }
}
