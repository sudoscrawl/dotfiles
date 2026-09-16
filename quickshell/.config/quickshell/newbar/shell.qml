import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./theme"
import "./components"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: bar

                required property var modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                }

                implicitHeight: Theme.barHeight + 6
                exclusiveZone: Theme.barHeight + 6
                color: "transparent"

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-bar"

                // Floating glassmorphism bar container
                Rectangle {
                    id: barBackground
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                        topMargin: 4
                        bottomMargin: 2
                    }

                    radius: Theme.radiusBar
                    color: Theme.bgAlpha

                    border {
                        width: 1
                        color: Theme.border
                    }

                    // LEFT REGION: Workspaces
                    RowLayout {
                        id: leftRegion
                        anchors {
                            left: parent.left
                            leftMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 8

                        Workspaces {}
                    }

                    // CENTER REGION: Clock
                    ClockWidget {
                        anchors.centerIn: parent
                        barWindow: bar
                    }

                    // RIGHT REGION
                    RowLayout {
                        id: rightRegion
                        anchors {
                            right: parent.right
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 4

                        MprisPlayer {}

                        SystemStats {
                            barWindow: bar
                        }

                        BrightnessWidget {
                            barWindow: bar
                        }

                        VolumeWidget {
                            barWindow: bar
                        }

                        NetworkWidget {
                            barWindow: bar
                        }

                        BluetoothWidget {
                            barWindow: bar
                        }

                        BatteryWidget {
                            barWindow: bar
                        }

                        NotificationsWidget {}

                        PowerMenuWidget {
                            barWindow: bar
                        }
                    }
                }
            }
        }
    }
}
