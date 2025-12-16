import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 800
    height: 700
    title: "Monitor postawy"
    color: "#f0f0f0"

    property bool menuOpen: false

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            id: sideBar
            Layout.fillHeight: true
            color: "#e0e0e0"
            Layout.preferredWidth: menuOpen ? 120 : 70

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 200 }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 20

                CustomButton {
                    setIcon: "resources/hamburger_menu_icon.png"
                    backgroundColor: "yellow"
                    onClicked: menuOpen = !menuOpen
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                }

                CustomButton {
                    setIcon: "resources/home.png"
                    text: menuOpen ? "Start" : ""
                }

                CustomButton {
                    setIcon: "resources/settings.png"
                    text: menuOpen ? "Settings" : ""
                }

                CustomButton {
                    setIcon: "resources/statistics.png"
                    text: menuOpen ? "Statistics" : ""
                }

                Item { Layout.fillHeight: true }
            }
        }

        ColumnLayout {
            Layout.rightMargin: 10

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                anchors.margins: 10

                Rectangle {
                    color: "black"
                    border.color: "lightgray"

                    radius: 20

                    Layout.preferredHeight: 400
                    Layout.fillWidth: true

                    Text {
                        text: "1. TU BĘDZIE KAMERA"
                        color: "white"
                        anchors.centerIn: parent
                    }
                }



                Rectangle {
                    Layout.preferredHeight: 400
                    Layout.fillWidth: true
                    color: "transparent"

                    CustomButton {
                        anchors.centerIn: parent
                        setIcon: "resources/start.png"
                        text: "START"
                        font.pixelSize: 36
                    }
                }

                Rectangle {
                    color: "white"
                    border.color: "lightgray"
                    radius: 20
                    Layout.columnSpan: 2
                    Layout.preferredHeight: 250
                    Layout.fillWidth: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Text {
                            text: "Last notification history"
                            font.pixelSize: 16
                            color: "#333"
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 15
                            clip: true

                            model: ListModel {
                                ListElement {
                                    message: "Monitor posture good"
                                    time: "1 minutes ago"
                                    status: "success"
                                }
                                ListElement {
                                    message: "Monitor posture good"
                                    time: "5 minutes ago"
                                    status: "success"
                                }
                                ListElement {
                                    message: "Posture corrected"
                                    time: "12 minutes ago"
                                    status: "success"
                                }
                                ListElement {
                                    message: "Bad posture detected"
                                    time: "15 minutes ago"
                                    status: "warning"
                                }
                            }

                            delegate: RowLayout {
                                width: ListView.view.width
                                spacing: 15

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: status === "success" ? "#4CAF50" :
                                           status === "warning" ? "#FF9800" : "#F44336"

                                    Text {
                                        text: status === "success" ? "✓" :
                                              status === "warning" ? "⚠" : "✗"
                                        color: "white"
                                        font.pixelSize: 18
                                        font.bold: true
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true

                                    Text {
                                        text: message
                                        font.pixelSize: 14
                                        color: "#333"
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: time
                                        font.pixelSize: 12
                                        color: "#999"
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
