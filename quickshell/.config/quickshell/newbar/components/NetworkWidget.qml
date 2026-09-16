import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    required property var barWindow

    implicitHeight: Theme.capsuleHeight
    implicitWidth: netCapsule.implicitWidth

    // ─────────────────────────────────────────────────────────────
    // CONNECTION STATE
    // ─────────────────────────────────────────────────────────────
    property bool isConnected: false
    property bool isWifi: false
    property bool isEthernet: false
    property string ssid: ""
    property int signalPercent: 0
    property string ipAddress: ""
    property bool isScanning: false
    property var networks: []
    property var savedSsids: []      // SSIDs that have a saved nmcli profile

    // Sheet state
    property string pendingSsid: ""
    property bool pendingIsEnterprise: false
    property bool pwSheetVisible: false
    property bool pwConnecting: false
    property string connectError: ""

    // Enterprise EAP fields
    property string eapMethod: "peap"         // peap | ttls | tls
    property string phase2Auth: "mschapv2"    // mschapv2 | pap | chap

    readonly property string netIcon: {
        if (isEthernet) return "󰈀";
        if (!isConnected) return "󰤮";
        if (signalPercent >= 80) return "󰤨";
        if (signalPercent >= 60) return "󰤥";
        if (signalPercent >= 40) return "󰤢";
        if (signalPercent >= 20) return "󰤟";
        return "󰤯";
    }

    function signalIcon(sig) {
        if (sig >= 80) return "󰤨";
        if (sig >= 60) return "󰤥";
        if (sig >= 40) return "󰤢";
        if (sig >= 20) return "󰤟";
        return "󰤯";
    }

    function signalColor(sig) {
        if (sig >= 60) return Theme.green;
        if (sig >= 35) return Theme.yellow;
        return Theme.red;
    }

    // Shell-safe single-quote escape for bash
    function shEscape(s) {
        return s.replace(/'/g, "'\\''");
    }

    // ─────────────────────────────────────────────────────────────
    // CONNECT LOGIC
    // ─────────────────────────────────────────────────────────────
    function requestConnect(net) {
        root.connectError = "";
        if (net.active) return;

        root.pendingSsid = net.ssid;
        var isEnt = net.security.toLowerCase().indexOf("802.1x") >= 0;
        root.pendingIsEnterprise = isEnt;

        var isOpen   = (net.security === "" || net.security === "--");
        var isSaved  = root.savedSsids.indexOf(net.ssid) >= 0;

        if (isOpen) {
            // Open network → connect directly
            root.pwConnecting = true;
            connectProc.mode = "open";
            connectProc.targetSsid = net.ssid;
            connectProc.targetPassword = "";
            connectProc.running = true;
        } else if (isSaved && !isEnt) {
            // Saved personal profile → bring up without re-asking password
            root.pwConnecting = true;
            connectProc.mode = "saved";
            connectProc.targetSsid = net.ssid;
            connectProc.targetPassword = "";
            connectProc.running = true;
        } else {
            // Need credentials — show sheet
            pwInput.text = "";
            eapIdentityInput.text = "";
            eapCaCertInput.text = "";
            eapAnonInput.text = "";
            root.eapMethod = "peap";
            root.phase2Auth = "mschapv2";
            root.pwSheetVisible = true;
            Qt.callLater(function() {
                isEnt ? eapIdentityInput.forceActiveFocus() : pwInput.forceActiveFocus();
            });
        }
    }

    function doPersonalConnect() {
        if (root.pwConnecting) return;
        root.connectError = "";
        root.pwConnecting = true;
        connectProc.mode = "personal";
        connectProc.targetSsid = root.pendingSsid;
        connectProc.targetPassword = pwInput.text;
        connectProc.running = true;
    }

    function doEnterpriseConnect() {
        if (root.pwConnecting) return;
        root.connectError = "";
        root.pwConnecting = true;
        enterpriseProc.targetSsid = root.pendingSsid;
        enterpriseProc.targetIdentity = eapIdentityInput.text;
        enterpriseProc.targetPassword = pwInput.text;
        enterpriseProc.targetEap = root.eapMethod;
        enterpriseProc.targetPhase2 = root.phase2Auth;
        enterpriseProc.targetCaCert = eapCaCertInput.text.trim();
        enterpriseProc.targetAnonIdentity = eapAnonInput.text.trim();
        enterpriseProc.running = true;
    }

    function dismissSheet() {
        root.pwSheetVisible = false;
        root.pendingSsid = "";
        root.pendingIsEnterprise = false;
        root.connectError = "";
        root.pwConnecting = false;
        pwInput.text = "";
    }

    function handleConnectResult(text) {
        var exitMatch = text.match(/EXIT:(\d+)/);
        var code = exitMatch ? parseInt(exitMatch[1]) : -1;
        root.pwConnecting = false;
        if (code === 0) {
            root.dismissSheet();
            refreshTimer.start();
        } else {
            // Pull last non-empty meaningful line as the error
            var clean = text.replace(/EXIT:\d+/, "").trim();
            var lines = clean.split("\n").filter(function(l) { return l.trim() !== ""; });
            root.connectError = lines.length > 0 ? lines[lines.length - 1].trim() : "Connection failed";
            // If this was a "saved" reconnect and it failed, drop back to password sheet
            if (connectProc.mode === "saved") {
                root.pwSheetVisible = true;
                Qt.callLater(function() { pwInput.forceActiveFocus(); });
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // PROCESSES — STATUS POLL
    // ─────────────────────────────────────────────────────────────
    Process {
        id: netProc
        command: ["bash", "-c",
            "wifi=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -n 1); " +
            "ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}'); " +
            "eth=$(nmcli -t -f type,state dev 2>/dev/null | grep 'ethernet:connected'); " +
            "echo \"$wifi|$eth|$ip\""
        ]
        running: true
        stdout: StdioCollector {
            onDataChanged: {
                try {
                    var parts = text.trim().split("|");
                    if (parts.length >= 3) {
                        var wifiPart = parts[0];
                        var ethPart  = parts[1];
                        var ipPart   = parts[2];
                        root.ipAddress = ipPart || "Disconnected";
                        if (ethPart && ethPart.indexOf("connected") !== -1) {
                            root.isConnected   = true;
                            root.isEthernet    = true;
                            root.isWifi        = false;
                            root.ssid          = "Ethernet";
                            root.signalPercent = 100;
                        } else if (wifiPart && wifiPart.indexOf("yes:") === 0) {
                            var w = wifiPart.split(":");
                            root.isConnected   = true;
                            root.isEthernet    = false;
                            root.isWifi        = true;
                            root.ssid          = w[1] || "Wi-Fi";
                            root.signalPercent = parseInt(w[2]) || 0;
                        } else {
                            root.isConnected   = false;
                            root.isEthernet    = false;
                            root.isWifi        = false;
                            root.ssid          = "Disconnected";
                            root.signalPercent = 0;
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: netProc.running = true }

    // ── Available network scanner ────────────────────────────────
    Process {
        id: scanProc
        command: ["bash", "-c",
            "nmcli -t -f active,ssid,signal,security dev wifi 2>/dev/null " +
            "| awk -F: 'BEGIN{OFS=\"|\"} {active=$1; ssid=$2; sig=$3; sec=$4; for(i=5;i<=NF;i++) sec=sec \":\" $i; print active,ssid,sig,sec}' " +
            "| sort -t'|' -k3 -rn " +
            "| awk -F'|' '!seen[$2]++'"
        ]
        running: false
        stdout: StdioCollector {
            onDataChanged: {
                if (text.trim() === "") { root.isScanning = false; return; }
                var lines = text.trim().split("\n");
                var result = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line === "") continue;
                    var p = line.split("|");
                    if (p.length < 4) continue;
                    var s = p[1];
                    if (s === "" || s === "--") continue;
                    result.push({
                        active:   p[0] === "yes",
                        ssid:     s,
                        signal:   parseInt(p[2]) || 0,
                        security: p[3] || ""
                    });
                }
                root.networks = result;
                root.isScanning = false;
            }
        }
    }

    // ── Saved profiles lister ────────────────────────────────────
    // Lists nmcli wifi connection names (which are usually the SSID)
    Process {
        id: savedConProc
        command: ["bash", "-c",
            "nmcli -t -f name,type con show 2>/dev/null | grep ':wifi$' | sed 's/:wifi$//'"
        ]
        running: false
        stdout: StdioCollector {
            onDataChanged: {
                if (text.trim() === "") return;
                root.savedSsids = text.trim().split("\n").map(function(l) { return l.trim(); });
            }
        }
    }

    // ── Personal / saved connect ─────────────────────────────────
    Process {
        id: connectProc
        property string mode: "open"   // "open" | "personal" | "saved"
        property string targetSsid: ""
        property string targetPassword: ""

        command: {
            var ssid = shEscape(targetSsid);
            if (mode === "saved") {
                return ["bash", "-c",
                    "nmcli con up id '" + ssid + "' 2>&1; echo \"EXIT:$?\""
                ];
            } else if (mode === "personal" && targetPassword !== "") {
                var pw = shEscape(targetPassword);
                return ["bash", "-c",
                    "nmcli dev wifi connect '" + ssid + "' password '" + pw + "' 2>&1; echo \"EXIT:$?\""
                ];
            } else {
                return ["bash", "-c",
                    "nmcli dev wifi connect '" + ssid + "' 2>&1; echo \"EXIT:$?\""
                ];
            }
        }
        running: false
        stdout: StdioCollector {
            onDataChanged: { root.handleConnectResult(text); }
        }
    }

    // ── Enterprise (802.1x) connect ──────────────────────────────
    // Deletes any old profile for this SSID, creates a fresh one, then brings it up
    Process {
        id: enterpriseProc
        property string targetSsid: ""
        property string targetIdentity: ""
        property string targetPassword: ""
        property string targetEap: "peap"
        property string targetPhase2: "mschapv2"
        property string targetCaCert: ""
        property string targetAnonIdentity: ""

        command: {
            var ssid     = shEscape(targetSsid);
            var identity = shEscape(targetIdentity);
            var pw       = shEscape(targetPassword);
            var caCert   = shEscape(targetCaCert);
            var anonId   = shEscape(targetAnonIdentity);

            var cmd = "nmcli con delete id '" + ssid + "' 2>/dev/null; " +
                "nmcli con add type wifi ssid '" + ssid + "' " +
                "connection.id '" + ssid + "' " +
                "wifi-sec.key-mgmt wpa-eap " +
                "802-1x.eap " + targetEap + " " +
                "802-1x.identity '" + identity + "' " +
                "802-1x.password '" + pw + "' ";

            // Phase2 only applies to PEAP and TTLS (not TLS client-cert auth)
            if (targetEap !== "tls") {
                cmd += "802-1x.phase2-auth " + targetPhase2 + " ";
            }
            if (targetCaCert !== "") {
                cmd += "802-1x.ca-cert '" + caCert + "' ";
            } else {
                // Disable server cert verification when no CA is provided (like GNOME does by default)
                cmd += "802-1x.ca-cert '' ";
            }
            if (targetAnonIdentity !== "") {
                cmd += "802-1x.anonymous-identity '" + anonId + "' ";
            }

            cmd += "2>&1 && nmcli con up id '" + ssid + "' 2>&1; echo \"EXIT:$?\"";
            return ["bash", "-c", cmd];
        }
        running: false
        stdout: StdioCollector {
            onDataChanged: { root.handleConnectResult(text); }
        }
    }

    function scanNetworks() {
        root.isScanning = true;
        root.networks = [];
        scanProc.running = true;
        savedConProc.running = true;
    }

    Timer {
        id: refreshTimer
        interval: 2500; repeat: false
        onTriggered: {
            netProc.running = true;
            root.scanNetworks();
        }
    }

    // ─────────────────────────────────────────────────────────────
    // STATUS BAR CAPSULE
    // ─────────────────────────────────────────────────────────────
    Rectangle {
        id: netCapsule
        anchors.fill: parent
        radius: Theme.radiusPill
        color: netMouse.containsMouse ? Theme.bgLight : "transparent"
        
        implicitWidth: 28
        implicitHeight: Theme.capsuleHeight

        RowLayout {
            id: netRow
            anchors.centerIn: parent
            spacing: 0

            Text {
                text: root.netIcon
                color: root.isConnected ? Theme.fgBright : Theme.fgMuted
                font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
            }
        }

        MouseArea {
            id: netMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!netPopup.visible) {
                    netPopup.visible = true;
                    netProc.running = true;
                    root.scanNetworks();
                } else {
                    netPopup.visible = false;
                    root.dismissSheet();
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // NETWORK POPUP
    // ─────────────────────────────────────────────────────────────
    PopupWindow {
        id: netPopup

        anchor.window: root.barWindow
        anchor.rect.x: Math.round(Math.max(12, Math.min(
            root.barWindow.width - width - 12,
            root.mapToItem(null, 0, 0).x + root.width / 2 - width / 2
        )))
        anchor.rect.y: root.barWindow.height + 2

        implicitWidth: 300
        implicitHeight: 400
        color: "transparent"
        visible: false
        grabFocus: true

        onVisibleChanged: { if (!visible) root.dismissSheet(); }

        // ── Outer card ───────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusPopup
            color: Theme.bgCard
            border { width: 1; color: Theme.borderFocus }
            clip: true

            // Inner rim (always on top)
            Rectangle {
                anchors { fill: parent; margins: 1 }
                radius: Theme.radiusPopup - 1
                color: "transparent"
                border { width: 1; color: "#15d5c6a5" }
                z: 20
            }

            // ── Header ──────────────────────────────────────────
            RowLayout {
                id: netHeader
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
                height: 50
                spacing: 10

                Rectangle {
                    width: 36; height: 36; radius: 10
                    color: root.isConnected ? "#1ab8bb26" : Theme.bgLight
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent
                        text: root.netIcon
                        color: root.isConnected ? Theme.green : Theme.fgMuted
                        font { family: Theme.fontMono; pixelSize: Theme.iconSizeMd }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: root.ssid !== "" ? root.ssid : "Wi-Fi"
                        color: Theme.fgBright
                        font { family: Theme.fontMono; pixelSize: Theme.fontSizeMd; weight: Font.Bold }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.isConnected
                            ? (root.isEthernet ? "Wired · " + root.ipAddress
                                               : root.signalPercent + "% · " + root.ipAddress)
                            : "Not connected"
                        color: Theme.fgMuted
                        font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Scan / refresh button
                Rectangle {
                    width: 28; height: 28; radius: 7
                    color: scanBtnHover.containsMouse ? Theme.bgLight : Theme.bgSubtle
                    border { width: 1; color: Theme.border }
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰑓"
                        color: root.isScanning ? Theme.yellow : Theme.fgMuted
                        font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                        RotationAnimation on rotation {
                            running: root.isScanning
                            from: 0; to: 360; duration: 900
                            loops: Animation.Infinite
                        }
                    }
                    MouseArea {
                        id: scanBtnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.scanNetworks()
                    }
                }
            }

            Rectangle {
                id: netDivider
                anchors { top: netHeader.bottom; left: parent.left; right: parent.right; topMargin: 2; leftMargin: 16; rightMargin: 16 }
                height: 1; color: Theme.borderSubtle
            }

            Text {
                id: netLabel
                anchors { top: netDivider.bottom; left: parent.left; right: parent.right; topMargin: 10; leftMargin: 16 }
                text: "Available Networks"
                color: Theme.fgDark
                font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs; weight: Font.Medium }
            }

            // ── Network list ─────────────────────────────────────
            ListView {
                id: netList
                anchors {
                    top: netLabel.bottom; bottom: parent.bottom
                    left: parent.left; right: parent.right
                    topMargin: 6; bottomMargin: 8; leftMargin: 8; rightMargin: 8
                }
                clip: true
                model: root.networks
                spacing: 3

                Item {
                    anchors.centerIn: parent
                    width: parent.width; height: 80
                    visible: root.networks.length === 0
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isScanning ? "󱕼" : "󰤮"
                            color: Theme.fgSubdued
                            font { family: Theme.fontMono; pixelSize: Theme.iconSizeLg }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isScanning ? "Scanning…" : "No networks found"
                            color: Theme.fgDark
                            font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                        }
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool isSaved: root.savedSsids.indexOf(modelData.ssid) >= 0
                    readonly property bool isEnt: modelData.security.toLowerCase().indexOf("802.1x") >= 0

                    width: ListView.view.width
                    height: 46
                    radius: Theme.radiusInner
                    color: modelData.active ? "#18b8bb26"
                                            : (netRowHover.containsMouse ? Theme.bgSubtle : "transparent")
                    border { width: 1; color: modelData.active ? "#33b8bb26" : "transparent" }
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 10

                        Text {
                            text: root.signalIcon(modelData.signal)
                            color: modelData.active ? Theme.green : root.signalColor(modelData.signal)
                            font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                        }

                        ColumnLayout {
                            spacing: 4
                            Layout.fillWidth: true

                            RowLayout {
                                spacing: 5
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.ssid
                                    color: modelData.active ? Theme.green : Theme.fgBright
                                    font {
                                        family: Theme.fontMono
                                        pixelSize: Theme.fontSizeSm
                                        weight: modelData.active ? Font.Bold : Font.Normal
                                    }
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Lock / enterprise icon
                                Text {
                                    visible: modelData.security !== "" && modelData.security !== "--"
                                    text: isEnt ? "󰒅" : "󰌾"
                                    color: isEnt ? Theme.yellow : Theme.fgDark
                                    font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                                }

                                // "Saved" badge
                                Rectangle {
                                    visible: isSaved && !modelData.active
                                    implicitWidth: savedBadgeLbl.implicitWidth + 8
                                    height: 14; radius: 4
                                    color: "#22fabd2f"
                                    Text {
                                        id: savedBadgeLbl
                                        anchors.centerIn: parent
                                        text: "Saved"
                                        color: Theme.yellow
                                        font { family: Theme.fontMono; pixelSize: 9; weight: Font.Medium }
                                    }
                                }

                                // "Connected" badge
                                Rectangle {
                                    visible: modelData.active
                                    width: 56; height: 14; radius: 4
                                    color: "#33b8bb26"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connected"
                                        color: Theme.green
                                        font { family: Theme.fontMono; pixelSize: 9; weight: Font.Medium }
                                    }
                                }
                            }

                            // Signal bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 3; radius: 2
                                color: Theme.bgLighter
                                Rectangle {
                                    width: parent.width * (modelData.signal / 100.0)
                                    height: parent.height; radius: 2
                                    color: root.signalColor(modelData.signal)
                                    opacity: 0.7
                                }
                            }
                        }

                        // Connect button (non-active)
                        Rectangle {
                            visible: !modelData.active
                            implicitWidth: connBtnLabel.implicitWidth + 18
                            height: 22; radius: 6
                            color: connHover.containsMouse ? "#2283a598" : "#1283a598"
                            border { width: 1; color: "#4483a598" }
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                id: connBtnLabel
                                anchors.centerIn: parent
                                // "Saved" networks reconnect with one click — label reflects that
                                text: (isSaved && !isEnt) ? "Reconnect" : "Connect"
                                color: Theme.blue
                                font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs; weight: Font.Medium }
                            }

                            MouseArea {
                                id: connHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.requestConnect(modelData)
                            }
                        }
                    }

                    MouseArea {
                        id: netRowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

            // ─────────────────────────────────────────────────────
            // CREDENTIAL SHEET  (slides up from bottom)
            // Adapts height & content for WPA-Personal vs Enterprise
            // ─────────────────────────────────────────────────────
            Rectangle {
                id: pwSheet
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }

                // Height expands for enterprise fields
                readonly property int personalHeight: 160
                readonly property int enterpriseHeight: 330
                height: root.pwSheetVisible
                    ? (root.pendingIsEnterprise ? enterpriseHeight : personalHeight)
                    : 0

                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                radius: Theme.radiusPopup
                // Square the top corners by overlapping
                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: Theme.radiusPopup
                    color: parent.color
                }

                color: Theme.bgAlt
                border { width: 1; color: Theme.borderFocus }
                clip: true
                z: 10

                opacity: root.pwSheetVisible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 10
                    // Only render contents when sheet is tall enough
                    visible: pwSheet.height > 40

                    // ── Sheet title row ──────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: root.pendingIsEnterprise ? "󰒅" : "󰌾"
                            color: Theme.yellow
                            font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                        }
                        Text {
                            text: root.pendingSsid
                            color: Theme.fgBright
                            font { family: Theme.fontMono; pixelSize: Theme.fontSizeMd; weight: Font.Bold }
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        // Security type label
                        Text {
                            text: root.pendingIsEnterprise ? "Enterprise" : "WPA Personal"
                            color: root.pendingIsEnterprise ? Theme.yellow : Theme.fgDark
                            font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                        }
                    }

                    // ── ENTERPRISE FIELDS (only visible for 802.1x) ──
                    // EAP Method selector
                    RowLayout {
                        visible: root.pendingIsEnterprise
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "EAP"
                            color: Theme.fgMuted
                            font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                            Layout.preferredWidth: 68
                        }

                        // Pill cycler: PEAP → TTLS → TLS → PEAP
                        Repeater {
                            model: ["peap", "ttls", "tls"]
                            delegate: Rectangle {
                                required property string modelData
                                required property int index
                                implicitWidth: eapMethodLbl.implicitWidth + 14
                                height: 22; radius: 6
                                color: root.eapMethod === modelData
                                    ? "#3383a598"
                                    : (eapM.containsMouse ? Theme.bgLighter : Theme.bgSubtle)
                                border {
                                    width: 1
                                    color: root.eapMethod === modelData ? "#6683a598" : Theme.border
                                }
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Text {
                                    id: eapMethodLbl
                                    anchors.centerIn: parent
                                    text: modelData.toUpperCase()
                                    color: root.eapMethod === modelData ? Theme.blue : Theme.fgMuted
                                    font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs; weight: Font.Medium }
                                }
                                MouseArea {
                                    id: eapM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.eapMethod = modelData
                                }
                            }
                        }
                    }

                    // Phase2 Auth (PEAP / TTLS only)
                    RowLayout {
                        visible: root.pendingIsEnterprise && root.eapMethod !== "tls"
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Auth"
                            color: Theme.fgMuted
                            font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                            Layout.preferredWidth: 68
                        }

                        Repeater {
                            model: ["mschapv2", "pap", "chap"]
                            delegate: Rectangle {
                                required property string modelData
                                required property int index
                                implicitWidth: phase2Lbl.implicitWidth + 14
                                height: 22; radius: 6
                                color: root.phase2Auth === modelData
                                    ? "#33fabd2f"
                                    : (p2M.containsMouse ? Theme.bgLighter : Theme.bgSubtle)
                                border {
                                    width: 1
                                    color: root.phase2Auth === modelData ? "#66fabd2f" : Theme.border
                                }
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Text {
                                    id: phase2Lbl
                                    anchors.centerIn: parent
                                    text: modelData.toUpperCase()
                                    color: root.phase2Auth === modelData ? Theme.yellow : Theme.fgMuted
                                    font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs; weight: Font.Medium }
                                }
                                MouseArea {
                                    id: p2M
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.phase2Auth = modelData
                                }
                            }
                        }
                    }

                    // Identity (username) — enterprise only
                    Rectangle {
                        visible: root.pendingIsEnterprise
                        Layout.fillWidth: true
                        height: 34; radius: 7
                        color: Theme.bgSubtle
                        border { width: 1; color: eapIdentityInput.activeFocus ? Theme.borderFocus : Theme.border }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                            spacing: 6
                            Text {
                                text: "󰀄"
                                color: Theme.fgDark
                                font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                            }
                            TextInput {
                                id: eapIdentityInput
                                Layout.fillWidth: true
                                color: Theme.fg
                                font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm }
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                Keys.onTabPressed: pwInput.forceActiveFocus()
                                Keys.onEscapePressed: root.dismissSheet()
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Username / Identity"
                                    color: Theme.fgDark
                                    font: parent.font
                                    visible: parent.text.length === 0 && !parent.activeFocus
                                }
                            }
                        }
                    }

                    // Anonymous identity (PEAP outer id — optional)
                    Rectangle {
                        visible: root.pendingIsEnterprise && root.eapMethod === "peap"
                        Layout.fillWidth: true
                        height: 34; radius: 7
                        color: Theme.bgSubtle
                        border { width: 1; color: eapAnonInput.activeFocus ? Theme.borderFocus : Theme.border }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                            spacing: 6
                            Text {
                                text: "󰅠"
                                color: Theme.fgDark
                                font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                            }
                            TextInput {
                                id: eapAnonInput
                                Layout.fillWidth: true
                                color: Theme.fg
                                font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm }
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                Keys.onEscapePressed: root.dismissSheet()
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Anonymous identity (optional)"
                                    color: Theme.fgDark
                                    font: parent.font
                                    visible: parent.text.length === 0 && !parent.activeFocus
                                }
                            }
                        }
                    }

                    // CA Certificate path (optional)
                    Rectangle {
                        visible: root.pendingIsEnterprise
                        Layout.fillWidth: true
                        height: 34; radius: 7
                        color: Theme.bgSubtle
                        border { width: 1; color: eapCaCertInput.activeFocus ? Theme.borderFocus : Theme.border }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                            spacing: 6
                            Text {
                                text: "󰄤"
                                color: Theme.fgDark
                                font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                            }
                            TextInput {
                                id: eapCaCertInput
                                Layout.fillWidth: true
                                color: Theme.fg
                                font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm }
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                Keys.onReturnPressed: pwInput.forceActiveFocus()
                                Keys.onEscapePressed: root.dismissSheet()
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "CA certificate path (optional)"
                                    color: Theme.fgDark
                                    font: parent.font
                                    visible: parent.text.length === 0 && !parent.activeFocus
                                }
                            }
                        }
                    }

                    // ── Password field (both personal and enterprise) ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: 34; radius: 7
                        color: Theme.bgSubtle
                        border { width: 1; color: pwInput.activeFocus ? Theme.borderFocus : Theme.border }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                            spacing: 6
                            Text {
                                text: "󰌾"
                                color: Theme.fgDark
                                font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                            }
                            TextInput {
                                id: pwInput
                                Layout.fillWidth: true
                                color: Theme.fg
                                font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm }
                                echoMode: eyeToggle.shown ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "●"
                                clip: true
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                Keys.onReturnPressed: root.pendingIsEnterprise ? root.doEnterpriseConnect() : root.doPersonalConnect()
                                Keys.onEscapePressed: root.dismissSheet()
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Password"
                                    color: Theme.fgDark
                                    font: parent.font
                                    visible: parent.text.length === 0 && !parent.activeFocus
                                }
                            }
                            // Eye toggle
                            Rectangle {
                                id: eyeToggle
                                property bool shown: false
                                width: 26; height: 26; radius: 6
                                color: eyeHover.containsMouse ? Theme.bgLighter : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: eyeToggle.shown ? "󰛑" : "󰛐"
                                    color: Theme.fgMuted
                                    font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                                }
                                MouseArea {
                                    id: eyeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: eyeToggle.shown = !eyeToggle.shown
                                }
                            }
                        }
                    }

                    // Error message
                    Text {
                        visible: root.connectError !== ""
                        text: root.connectError
                        color: Theme.red
                        font { family: Theme.fontMono; pixelSize: Theme.fontSizeXs }
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                    }

                    // ── Action buttons ───────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 30; radius: 7
                            color: cancelHover.containsMouse ? Theme.bgLighter : Theme.bgSubtle
                            border { width: 1; color: Theme.border }
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: Theme.fgMuted
                                font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm }
                            }
                            MouseArea {
                                id: cancelHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.dismissSheet()
                            }
                        }

                        Rectangle {
                            id: connectBtn
                            Layout.fillWidth: true
                            height: 30; radius: 7
                            color: {
                                if (root.pwConnecting) return "#1283a598";
                                return connectBtnHover.containsMouse ? "#3383a598" : "#2283a598";
                            }
                            border { width: 1; color: "#4483a598" }
                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    visible: root.pwConnecting
                                    text: "󰑓"
                                    color: Theme.blue
                                    font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                                    RotationAnimation on rotation {
                                        running: root.pwConnecting
                                        from: 0; to: 360; duration: 900
                                        loops: Animation.Infinite
                                    }
                                }
                                Text {
                                    text: root.pwConnecting ? "Connecting…" : "Connect"
                                    color: Theme.blue
                                    font { family: Theme.fontMono; pixelSize: Theme.fontSizeSm; weight: Font.Medium }
                                }
                            }

                            MouseArea {
                                id: connectBtnHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: root.pwConnecting ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (root.pendingIsEnterprise) root.doEnterpriseConnect();
                                    else root.doPersonalConnect();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
