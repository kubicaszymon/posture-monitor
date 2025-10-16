import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 800
    height: 600
    title: "Posture Monitor"
    
    color: "#f5f5f5"
    
    // Menu Bar
    menuBar: MenuBar {
        Menu {
            title: "Plik"
            MenuItem {
                text: "Ustawienia"
                onTriggered: settingsDialog.open()
            }
            MenuSeparator {}
            MenuItem {
                text: "Wyjście"
                onTriggered: Qt.quit()
            }
        }
        
        Menu {
            title: "Widok"
            MenuItem {
                text: "Pokaż podgląd kamery"
                checkable: true
                checked: true
                onCheckedChanged: cameraPreview.visible = checked
            }
        }
        
        Menu {
            title: "Pomoc"
            MenuItem {
                text: "O aplikacji"
                onTriggered: aboutDialog.open()
            }
        }
    }
    
    // Main content
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        // Status bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "white"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
                
                // Status indicator
                Rectangle {
                    width: 50
                    height: 50
                    radius: 25
                    color: application.isRunning ? "#4CAF50" : "#9E9E9E"
                    
                    SequentialAnimation on opacity {
                        running: application.isRunning
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 1000 }
                        NumberAnimation { to: 1.0; duration: 1000 }
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    Text {
                        text: application.isRunning ? "AKTYWNY" : "NIEAKTYWNY"
                        font.pixelSize: 20
                        font.bold: true
                        color: application.isRunning ? "#4CAF50" : "#9E9E9E"
                    }
                    
                    Text {
                        text: application.status
                        font.pixelSize: 14
                        color: "#666666"
                    }
                }
                
                Button {
                    text: application.isRunning ? "Stop" : "Start"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 50
                    
                    background: Rectangle {
                        color: parent.pressed ? (application.isRunning ? "#d32f2f" : "#388e3c") :
                               parent.hovered ? (application.isRunning ? "#e53935" : "#43a047") :
                               (application.isRunning ? "#f44336" : "#4CAF50")
                        radius: 5
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: application.toggleMonitoring
                    }
            }
        }
        
        // Camera preview
        Rectangle {
            id: cameraPreview
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1a1a1a"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1
            
            Image {
                id: cameraImage
                anchors.fill: parent
                anchors.margins: 10
                fillMode: Image.PreserveAspectFit
                source: "" // Będzie aktualizowane z C++
                
                Text {
                    anchors.centerIn: parent
                    text: cameraManager.isActive ? "Podgląd kamery" : "Kamera nieaktywna"
                    color: "white"
                    font.pixelSize: 18
                    visible: cameraImage.status !== Image.Ready
                }
            }
            
            // Overlay z informacjami
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                width: 200
                height: infoColumn.height + 20
                color: "#cc000000"
                radius: 8
                visible: application.isRunning
                
                ColumnLayout {
                    id: infoColumn
                    anchors.centerIn: parent
                    width: parent.width - 20
                    spacing: 10
                    
                    Text {
                        text: "Analiza w czasie rzeczywistym"
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#666666"
                    }
                    
                    Text {
                        text: "Model: " + (postureAnalyzer.modelLoaded ? "Załadowany" : "Brak")
                        color: postureAnalyzer.modelLoaded ? "#4CAF50" : "#FFA000"
                        font.pixelSize: 10
                        Layout.fillWidth: true
                    }
                }
            }
        }
        
        // Statistics panel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: "white"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1
            
            GridLayout {
                anchors.fill: parent
                anchors.margins: 20
                columns: 3
                rowSpacing: 10
                columnSpacing: 20
                
                // Statistic item template
                Repeater {
                    model: [
                        { title: "Czas monitoringu", value: "0:00:00"},
                        { title: "Nieprawidłowe postawy", value: "0"},
                        { title: "Skuteczność", value: "100%"}
                    ]
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        
                        Text {
                            text: modelData.icon + " " + modelData.title
                            font.pixelSize: 12
                            color: "#666666"
                        }
                        
                        Text {
                            text: modelData.value
                            font.pixelSize: 20
                            font.bold: true
                            color: "#333333"
                        }
                    }
                }
            }
        }
    }
    
    // Settings Dialog
    Dialog {
        id: settingsDialog
        title: "Ustawienia"
        width: 500
        height: 400
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        
        contentItem: ColumnLayout {
            spacing: 20
            
            GroupBox {
                title: "Kamera"
                Layout.fillWidth: true
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    
                    RowLayout {
                        Text { text: "Indeks kamery:" }
                        SpinBox {
                            from: 0
                            to: 10
                            value: settingsManager.cameraIndex
                            onValueChanged: settingsManager.cameraIndex = value
                        }
                    }
                    
                    RowLayout {
                        Text { text: "Rozdzielczość:" }
                        SpinBox {
                            from: 320
                            to: 1920
                            stepSize: 160
                            value: settingsManager.cameraWidth
                            onValueChanged: settingsManager.cameraWidth = value
                        }
                        Text { text: "x" }
                        SpinBox {
                            from: 240
                            to: 1080
                            stepSize: 120
                            value: settingsManager.cameraHeight
                            onValueChanged: settingsManager.cameraHeight = value
                        }
                    }
                }
            }
            
            GroupBox {
                title: "Powiadomienia"
                Layout.fillWidth: true
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    
                    CheckBox {
                        text: "Włącz powiadomienia"
                        checked: settingsManager.notificationsEnabled
                        onCheckedChanged: settingsManager.notificationsEnabled = checked
                    }
                    
                    RowLayout {
                        Text { text: "Cooldown (sekundy):" }
                        SpinBox {
                            from: 10
                            to: 300
                            stepSize: 10
                            value: settingsManager.notificationCooldown
                            onValueChanged: settingsManager.notificationCooldown = value
                        }
                    }
                }
            }
            
            GroupBox {
                title: "Model"
                Layout.fillWidth: true
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        TextField {
                            id: modelPathField
                            Layout.fillWidth: true
                            placeholderText: "Ścieżka do modelu..."
                            text: settingsManager.modelPath
                        }
                        
                        Button {
                            text: "Przeglądaj"
                            onClicked: {
                                // TODO: Dodać FileDialog
                                console.log("Przeglądanie plików...")
                            }
                        }
                    }
                    
                    Button {
                        text: "Załaduj model"
                        enabled: modelPathField.text.length > 0
                        onClicked: {
                            settingsManager.modelPath = modelPathField.text
                            postureAnalyzer.loadModel(modelPathField.text)
                        }
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
            
            RowLayout {
                Layout.fillWidth: true
                
                Button {
                    text: "Reset do domyślnych"
                    onClicked: settingsManager.resetToDefaults()
                }
                
                Item { Layout.fillWidth: true }
                
                Button {
                    text: "Zapisz"
                    onClicked: {
                        settingsManager.saveSettings()
                        settingsDialog.close()
                    }
                }
                
                Button {
                    text: "Anuluj"
                    onClicked: settingsDialog.close()
                }
            }
        }
    }
    
    // About Dialog
    Dialog {
        id: aboutDialog
        title: "O aplikacji"
        width: 400
        height: 300
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        
        contentItem: ColumnLayout {
            spacing: 20
            
            Text {
                text: "Posture Monitor"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: "Wersja 0.1.0"
                font.pixelSize: 14
                color: "#666666"
                Layout.alignment: Qt.AlignHCenter
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#e0e0e0"
            }
            
            Text {
                text: "Aplikacja do monitorowania postawy podczas pracy przy komputerze.\n\n" +
                      "Wykorzystuje machine learning do wykrywania nieprawidłowej postawy " +
                      "i ostrzega użytkownika w czasie rzeczywistym."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            
            Item { Layout.fillHeight: true }
            
            Button {
                text: "Zamknij"
                Layout.alignment: Qt.AlignHCenter
                onClicked: aboutDialog.close()
            }
        }
    }
    
    // Connections for camera updates
    Connections {
        target: cameraManager
        function onFrameUpdated(frame) {
            // Aktualizacja obrazu z kamery
            // W rzeczywistości trzeba będzie przekonwertować QImage na URL
            // lub użyć QQuickImageProvider
        }
    }
}