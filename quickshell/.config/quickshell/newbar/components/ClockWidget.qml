import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id: root

    required property var barWindow
    property bool use24Hour: true

    implicitHeight: Theme.capsuleHeight
    implicitWidth: clockCapsule.implicitWidth

    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }

    // Main capsule on the status bar
    Rectangle {
        id: clockCapsule
        anchors.fill: parent
        radius: Theme.radiusPill
        color: clockMouse.containsMouse ? Theme.bgLight : "transparent"

        implicitWidth: clockLayout.implicitWidth + 14
        implicitHeight: Theme.capsuleHeight

        RowLayout {
            id: clockLayout
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.use24Hour
                    ? Qt.formatDateTime(systemClock.date, "HH:mm")
                    : Qt.formatDateTime(systemClock.date, "hh:mm AP")
                color: Theme.fgBright
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.fontSizeRegular
                    weight: Font.Medium
                }
            }

            Text {
                text: Qt.formatDateTime(systemClock.date, "ddd, d MMM")
                color: Theme.fgMuted
                font {
                    family: Theme.fontMono
                    pixelSize: Theme.fontSizeSm
                }
            }
        }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                calendarPopup.visible = !calendarPopup.visible;
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // INTERACTIVE CALENDAR POPUP
    // ─────────────────────────────────────────────────────────────
    PopupWindow {
        id: calendarPopup

        anchor.window: root.barWindow
        anchor.rect.x: Math.round(root.barWindow.width / 2 - width / 2)
        anchor.rect.y: root.barWindow.height + 2

        implicitWidth: 350
        implicitHeight: 450
        color: "transparent"
        visible: false
        grabFocus: true

        // State for browsing months
        property int viewYear: new Date().getFullYear()
        property int viewMonth: new Date().getMonth() // 0-11

        readonly property var monthNames: [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]

        function resetToToday() {
            var now = new Date();
            viewYear = now.getFullYear();
            viewMonth = now.getMonth();
        }

        function prevMonth() {
            if (viewMonth === 0) {
                viewMonth = 11;
                viewYear--;
            } else {
                viewMonth--;
            }
        }

        function nextMonth() {
            if (viewMonth === 11) {
                viewMonth = 0;
                viewYear++;
            } else {
                viewMonth++;
            }
        }

        // Generate 42 calendar day cells
        readonly property var calendarCells: {
            var firstDay = new Date(viewYear, viewMonth, 1).getDay(); // 0 is Sunday
            var offset = (firstDay + 6) % 7; // Monday = 0
            var daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
            var daysInPrev = new Date(viewYear, viewMonth, 0).getDate();
            var now = new Date();
            var isCurrentYearMonth = (now.getFullYear() === viewYear && now.getMonth() === viewMonth);

            var list = [];
            // Days from previous month
            for (var i = offset - 1; i >= 0; i--) {
                list.push({
                    dayNum: daysInPrev - i,
                    isCurrentMonth: false,
                    isToday: false
                });
            }
            // Days in current month
            for (var d = 1; d <= daysInMonth; d++) {
                list.push({
                    dayNum: d,
                    isCurrentMonth: true,
                    isToday: (isCurrentYearMonth && now.getDate() === d)
                });
            }
            // Days in next month
            var remaining = 42 - list.length;
            for (var n = 1; n <= remaining; n++) {
                list.push({
                    dayNum: n,
                    isCurrentMonth: false,
                    isToday: false
                });
            }
            return list;
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusPopup
            color: Theme.bgCard
            border {
                width: 1
                color: Theme.borderFocus
            }

            // Inner subtle rim
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Theme.radiusPopup - 1
                color: "transparent"
                border {
                    width: 1
                    color: "#15d5c6a5"
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // TOP CLOCK & DATE BANNER
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: root.use24Hour
                                ? Qt.formatDateTime(systemClock.date, "HH:mm:ss")
                                : Qt.formatDateTime(systemClock.date, "hh:mm:ss AP")
                            color: Theme.fgBright
                            font {
                                family: Theme.fontMono
                                pixelSize: Theme.fontSizeTitle
                                weight: Font.Bold
                            }
                        }

                        Text {
                            text: Qt.formatDateTime(systemClock.date, "dddd, MMMM d, yyyy")
                            color: Theme.fgMuted
                            font {
                                family: Theme.fontMono
                                pixelSize: Theme.fontSizeRegular
                            }
                        }
                    }

                    // 12/24H TOGGLE PILL
                    Rectangle {
                        implicitWidth: 62
                        implicitHeight: 28
                        radius: 14
                        color: formatMouse.containsMouse ? Theme.bgLight : Theme.bgAlt
                        border {
                            width: 1
                            color: Theme.border
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.use24Hour ? "24H" : "12H"
                            color: Theme.yellow
                            font {
                                family: Theme.fontMono
                                pixelSize: Theme.fontSizeSm
                                weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: formatMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.use24Hour = !root.use24Hour;
                            }
                        }
                    }
                }

                // DIVIDER
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderSubtle
                }

                // CALENDAR HEADER: Month Year & Nav
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: calendarPopup.monthNames[calendarPopup.viewMonth] + " " + calendarPopup.viewYear
                        color: Theme.fgBright
                        font {
                            family: Theme.fontMono
                            pixelSize: Theme.fontSizeLg
                            weight: Font.Bold
                        }
                        Layout.fillWidth: true
                    }

                    // Today Button
                    Rectangle {
                        implicitWidth: 50
                        implicitHeight: 24
                        radius: 6
                        color: todayMouse.containsMouse ? Theme.bgLight : Theme.bgAlt
                        border {
                            width: 1
                            color: Theme.border
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Today"
                            color: Theme.fg
                            font {
                                family: Theme.fontMono
                                pixelSize: Theme.fontSizeXs
                                weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: todayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendarPopup.resetToToday()
                        }
                    }

                    // Prev Month
                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 24
                        radius: 6
                        color: prevMouse.containsMouse ? Theme.bgLight : Theme.bgAlt
                        border { width: 1; color: Theme.border }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅁"
                            color: Theme.fg
                            font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendarPopup.prevMonth()
                        }
                    }

                    // Next Month
                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 24
                        radius: 6
                        color: nextMouse.containsMouse ? Theme.bgLight : Theme.bgAlt
                        border { width: 1; color: Theme.border }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅂"
                            color: Theme.fg
                            font { family: Theme.fontMono; pixelSize: Theme.iconSizeSm }
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendarPopup.nextMonth()
                        }
                    }
                }

                // CALENDAR GRID
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Days of week header (Mo Tu We Th Fr Sa Su)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                            delegate: Item {
                                Layout.fillWidth: true
                                height: 20
                                required property string modelData

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    color: (parent.modelData === "Sa" || parent.modelData === "Su") ? Theme.accent : Theme.fgMuted
                                    font {
                                        family: Theme.fontMono
                                        pixelSize: Theme.fontSizeSm
                                        weight: Font.Bold
                                    }
                                }
                            }
                        }
                    }

                    // 6 rows x 7 cols = 42 day cells
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        rowSpacing: 3
                        columnSpacing: 2

                        Repeater {
                            model: calendarPopup.calendarCells

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                radius: 6
                                required property var modelData

                                color: {
                                    if (modelData.isToday) return Theme.yellow;
                                    if (dayMouse.containsMouse && modelData.isCurrentMonth) return Theme.bgLight;
                                    return "transparent";
                                }

                                border {
                                    width: 1
                                    color: modelData.isToday ? Theme.yellowDim : (dayMouse.containsMouse && modelData.isCurrentMonth ? Theme.borderHover : "transparent")
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.dayNum
                                    font {
                                        family: Theme.fontMono
                                        pixelSize: Theme.fontSizeSm
                                        weight: modelData.isToday ? Font.Bold : Font.Normal
                                    }
                                    color: {
                                        if (modelData.isToday) return Theme.bg; // High contrast
                                        if (modelData.isCurrentMonth) return Theme.fg;
                                        return Theme.fgDark;
                                    }
                                }

                                MouseArea {
                                    id: dayMouse
                                    anchors.fill: parent
                                    hoverEnabled: modelData.isCurrentMonth
                                    cursorShape: modelData.isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                                }
                            }
                        }
                    }
                }

                // BOTTOM FOOTER: UPTIME
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderSubtle
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "󰅐 Uptime"
                        color: Theme.accent
                        font {
                            family: Theme.fontMono
                            pixelSize: Theme.fontSizeSm
                        }
                    }

                    Text {
                        id: uptimeText
                        text: "loading..."
                        color: Theme.fgMuted
                        font {
                            family: Theme.fontMono
                            pixelSize: Theme.fontSizeSm
                        }
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }

        // Process to read uptime from /proc/uptime
        Process {
            id: uptimeProc
            command: ["awk", "{h=int($1/3600); m=int(($1%3600)/60); printf(\"%dh %dm\", h, m)}", "/proc/uptime"]
            running: true
            stdout: StdioCollector {
                onDataChanged: {
                    uptimeText.text = text.trim();
                }
            }
        }

        Timer {
            interval: 30000
            running: calendarPopup.visible
            repeat: true
            onTriggered: uptimeProc.running = true
        }

        onVisibleChanged: {
            if (visible) {
                uptimeProc.running = true;
            }
        }
    }
}
