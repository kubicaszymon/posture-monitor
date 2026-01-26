import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1200
    height: 800
    title: "Monitor Postawy - Rozbudowane Statystyki"
    color: "#f0f0f0"

    property bool menuOpen: false
    property bool isMonitoring: postureMonitor.isMonitoring
    property bool closeOnExit: false
    property string currentView: "monitoring"  // monitoring, stats-current, stats-history, stats-compare

    // Opcja wyciszenia ostrzeżeń o złej postawie
    property bool mutePostureWarnings: false

    // Globalna property dla statystyk bieżącej sesji - aktualizowana przez sygnał
    property var currentSessionStats: statisticsManager.get_current_session_stats()

    // Funkcja do odświeżania statystyk
    function refreshCurrentSessionStats() {
        currentSessionStats = statisticsManager.get_current_session_stats()
    }

    onClosing: function(close) {
        if (closeOnExit) {
            console.log("✓ Zamykanie aplikacji...")
            close.accepted = true
        } else {
            console.log("✓ Ukrywanie do tray...")
            close.accepted = false
            mainWindow.hide()
        }
    }

    // Timer do odświeżania statystyk
    Timer {
        id: statsRefreshTimer
        interval: 5000  // Co 5 sekund
        running: isMonitoring && currentView.startsWith("stats")
        repeat: true
        onTriggered: {
            // Wymusza odświeżenie statystyk
            if (currentView === "stats-current") {
                currentSessionCanvas.requestPaint()
            }
        }
    }

    ListModel {
        id: notificationModel
    }

    Connections {
        target: postureMonitor
        function onNotificationAdded(message, time, status) {
            notificationModel.insert(0, {
                "message": message,
                "time": time,
                "status": status
            })
            if (notificationModel.count > 20) {
                notificationModel.remove(notificationModel.count - 1)
            }
        }

        function onCameraImageChanged(imagePath) {
            console.log("Nowy obraz kamery:", imagePath)
        }

        function onBadPostureWarning(duration) {
            console.log("OSTRZEZENIE: Zla postawa przez", duration, "sekund!")
            // Pokaż ostrzeżenie tylko jeśli nie jest wyciszone
            if (!mutePostureWarnings) {
                badPostureWarningDialog.durationSeconds = duration
                badPostureWarningDialog.open()
            }
        }

        function onCameraInfoChanged(info) {
            console.log("Info o kamerze:", info)
            cameraInfoText.text = info
        }
    }

    Connections {
        target: statisticsManager
        function onSessionDataChanged() {
            console.log("📊 Dane sesji zaktualizowane")
            // Odśwież globalne statystyki - to automatycznie zaktualizuje wszystkie karty
            refreshCurrentSessionStats()
            if (currentView === "stats-current") {
                currentSessionCanvas.requestPaint()
            }
        }
        
        function onHistoricalDataChanged() {
            console.log("📚 Historia zaktualizowana")
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // Boczny panel
        Rectangle {
            id: sideBar
            Layout.fillHeight: true
            color: "#2c3e50"
            Layout.preferredWidth: menuOpen ? 220 : 70

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 200 }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15

                Button {
                    text: "☰"
                    font.pixelSize: 24
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 50
                    onClicked: menuOpen = !menuOpen
                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                    
                    background: Rectangle {
                        color: parent.pressed ? "#34495e" : "#3498db"
                        radius: 8
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: parent.font.pixelSize
                    }
                }

                // Monitoring
                Button {
                    text: menuOpen ? "🏠 Monitoring" : "🏠"
                    font.pixelSize: menuOpen ? 13 : 20
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    
                    background: Rectangle {
                        color: currentView === "monitoring" ? "#2980b9" : 
                               (parent.pressed ? "#34495e" : "#3498db")
                        radius: 8
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: menuOpen ? Text.AlignLeft : Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: parent.font.pixelSize
                        leftPadding: menuOpen ? 10 : 0
                    }
                    
                    onClicked: currentView = "monitoring"
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: "#34495e"
                }

                Text {
                    text: menuOpen ? "STATYSTYKI" : "📊"
                    color: "#95a5a6"
                    font.pixelSize: 11
                    font.bold: true
                    Layout.fillWidth: true
                    horizontalAlignment: menuOpen ? Text.AlignLeft : Text.AlignHCenter
                    leftPadding: menuOpen ? 10 : 0
                }

                // Aktualna sesja
                Button {
                    text: menuOpen ? "📊 Aktualna" : "📊"
                    font.pixelSize: menuOpen ? 13 : 20
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    
                    background: Rectangle {
                        color: currentView === "stats-current" ? "#8e44ad" : 
                               (parent.pressed ? "#7d3c98" : "#9b59b6")
                        radius: 8
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: menuOpen ? Text.AlignLeft : Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: parent.font.pixelSize
                        leftPadding: menuOpen ? 10 : 0
                    }
                    
                    onClicked: currentView = "stats-current"
                }

                // Historia
                Button {
                    text: menuOpen ? "📚 Historia" : "📚"
                    font.pixelSize: menuOpen ? 13 : 20
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    
                    background: Rectangle {
                        color: currentView === "stats-history" ? "#16a085" : 
                               (parent.pressed ? "#138d75" : "#1abc9c")
                        radius: 8
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: menuOpen ? Text.AlignLeft : Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: parent.font.pixelSize
                        leftPadding: menuOpen ? 10 : 0
                    }
                    
                    onClicked: currentView = "stats-history"
                }

                // Porównanie
                Button {
                    text: menuOpen ? "🔄 Porównaj" : "🔄"
                    font.pixelSize: menuOpen ? 13 : 20
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    
                    background: Rectangle {
                        color: currentView === "stats-compare" ? "#d35400" : 
                               (parent.pressed ? "#ba4a00" : "#e67e22")
                        radius: 8
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: menuOpen ? Text.AlignLeft : Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: parent.font.pixelSize
                        leftPadding: menuOpen ? 10 : 0
                    }
                    
                    onClicked: currentView = "stats-compare"
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: "#34495e"
                }

                // Ustawienia
                Button {
                    text: menuOpen ? "⚙️ Ustawienia" : "⚙️"
                    font.pixelSize: menuOpen ? 13 : 20
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    onClicked: settingsDialog.open()
                    
                    background: Rectangle {
                        color: parent.pressed ? "#7f8c8d" : "#95a5a6"
                        radius: 8
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: menuOpen ? Text.AlignLeft : Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: parent.font.pixelSize
                        leftPadding: menuOpen ? 10 : 0
                    }
                }

                Item { Layout.fillHeight: true }

                // Ukryj
                Button {
                    text: menuOpen ? "📥 Ukryj" : "📥"
                    font.pixelSize: menuOpen ? 13 : 20
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    onClicked: mainWindow.hide()
                    
                    background: Rectangle {
                        color: parent.pressed ? "#c0392b" : "#e74c3c"
                        radius: 8
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: menuOpen ? Text.AlignLeft : Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: parent.font.pixelSize
                        leftPadding: menuOpen ? 10 : 0
                    }
                }
            }
        }

        // Główna zawartość
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: {
                if (currentView === "monitoring") return 0
                if (currentView === "stats-current") return 1
                if (currentView === "stats-history") return 2
                if (currentView === "stats-compare") return 3
                return 0
            }

            // ============================================
            // WIDOK 1: MONITORING
            // ============================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    spacing: 10

                    // Kamera
                    Rectangle {
                        color: "#1a1a1a"
                        border.color: isMonitoring ? "#27ae60" : "#333333"
                        border.width: 3
                        radius: 15
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                text: "📹 PODGLĄD KAMERY"
                                color: "#888888"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#000000"
                                radius: 10

                                // Placeholder - tylko gdy nie ma jeszcze obrazu
                                Rectangle {
                                    id: cameraPlaceholder
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    color: "#1a1a1a"
                                    visible: postureMonitor.cameraImage === ""

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 10

                                        Text {
                                            text: "Kamera"
                                            color: "#666666"
                                            font.pixelSize: 48
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        Text {
                                            text: "Ladowanie podgladu..."
                                            color: "#888888"
                                            font.pixelSize: 14
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }

                                // Obraz z kamery
                                Image {
                                    id: cameraImage
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    fillMode: Image.PreserveAspectFit
                                    source: postureMonitor.cameraImage
                                    cache: false
                                    asynchronous: false
                                    visible: postureMonitor.cameraImage !== ""
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                color: isMonitoring ? "#27ae6044" : "#95a5a644"
                                radius: 5

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: isMonitoring ? "● KAMERA AKTYWNA" : "○ KAMERA NIEAKTYWNA"
                                        color: isMonitoring ? "#27ae60" : "#95a5a6"
                                        font.pixelSize: 12
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        id: cameraInfoText
                                        text: isMonitoring ? postureMonitor.getCameraInfo() : "Wybierz kamerę w ustawieniach"
                                        color: "#7f8c8d"
                                        font.pixelSize: 9
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }
                    }

                    // Panel kontrolny
                    Rectangle {
                        color: "white"
                        border.color: "#ddd"
                        border.width: 2
                        radius: 15
                        Layout.preferredWidth: 300
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 25
                            width: parent.width - 40

                            Rectangle {
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 60
                                color: isMonitoring ? "#27ae60" : "#95a5a6"
                                radius: 10
                                Layout.alignment: Qt.AlignHCenter

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: isMonitoring ? "ANALIZA AKTYWNA" : "ANALIZA NIEAKTYWNA"
                                        color: "white"
                                        font.pixelSize: 12
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }

                            Button {
                                text: isMonitoring ? "STOP ANALIZA" : "START ANALIZA"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.preferredWidth: 220
                                Layout.preferredHeight: 50
                                Layout.alignment: Qt.AlignHCenter

                                background: Rectangle {
                                    color: parent.pressed ?
                                           (isMonitoring ? "#c0392b" : "#229954") :
                                           (isMonitoring ? "#e74c3c" : "#27ae60")
                                    radius: 10
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font: parent.font
                                }

                                onClicked: {
                                    if (isMonitoring) {
                                        postureMonitor.stopMonitoring()
                                    } else {
                                        postureMonitor.startMonitoring()
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                color: "#ecf0f1"
                                radius: 10

                                GridLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    columns: 2
                                    rowSpacing: 5
                                    columnSpacing: 10

                                    Text {
                                        text: "✅ Dobre:"
                                        font.pixelSize: 12
                                        color: "#27ae60"
                                    }

                                    Text {
                                        text: currentSessionStats.good
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#27ae60"
                                    }

                                    Text {
                                        text: "⚠️ Złe:"
                                        font.pixelSize: 12
                                        color: "#e74c3c"
                                    }

                                    Text {
                                        text: currentSessionStats.bad
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#e74c3c"
                                    }
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 2
                                color: "#ddd"
                            }
                            
                            Button {
                                text: "📥 Export CSV"
                                font.pixelSize: 12
                                font.bold: true
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                
                                background: Rectangle {
                                    color: parent.pressed ? "#3498db" : "#5dade2"
                                    radius: 8
                                }
                                
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font: parent.font
                                }
                                
                                onClicked: {
                                    var path = statisticsManager.export_current_session_csv()
                                    exportSuccessNotification.message = "✅ Eksport zapisany:\n" + path
                                    exportSuccessNotification.open()
                                }
                            }
                        }
                    }
                }

                // Historia powiadomień
                Rectangle {
                    color: "white"
                    border.color: "#ddd"
                    border.width: 2
                    radius: 15
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Text {
                            text: "📜 Historia sprawdzeń"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#2c3e50"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            color: "#ecf0f1"
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10
                            clip: true
                            model: notificationModel

                            delegate: Rectangle {
                                width: ListView.view ? ListView.view.width : 0
                                height: 60
                                color: "#f8f9fa"
                                radius: 10
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 15

                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 20
                                        color: model.status === "success" ? "#27ae60" :
                                               model.status === "warning" ? "#f39c12" : "#e74c3c"

                                        Text {
                                            text: model.status === "success" ? "✓" :
                                                  model.status === "warning" ? "⚠" : "✗"
                                            color: "white"
                                            font.pixelSize: 20
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 2
                                        Layout.fillWidth: true

                                        Text {
                                            text: model.message
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#2c3e50"
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "🕐 " + model.time
                                            font.pixelSize: 10
                                            color: "#7f8c8d"
                                        }
                                    }
                                }
                            }
                            
                            ScrollBar.vertical: ScrollBar {}
                        }
                    }
                }
            }

            // ============================================
            // WIDOK 2: STATYSTYKI AKTUALNEJ SESJI
            // ============================================
            ScrollView {
                clip: true
                
                ColumnLayout {
                    width: parent.parent.width - 20
                    spacing: 15
                    
                    Text {
                        text: "📊 Aktualna sesja"
                        font.pixelSize: 28
                        font.bold: true
                        color: "#2c3e50"
                        Layout.topMargin: 10
                    }

                    // Karty statystyk
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: 15
                        rowSpacing: 15

                        // Używamy globalnej property currentSessionStats z głównego okna

                        // Czas trwania
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            color: "#3498db"
                            radius: 15
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 10
                                
                                Text {
                                    text: "⏱️"
                                    font.pixelSize: 40
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: currentSessionStats.duration + " min"
                                    font.pixelSize: 28
                                    font.bold: true
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: "Czas trwania"
                                    font.pixelSize: 13
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Łącznie
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            color: "#9b59b6"
                            radius: 15
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 10
                                
                                Text {
                                    text: "📋"
                                    font.pixelSize: 40
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: currentSessionStats.total
                                    font.pixelSize: 28
                                    font.bold: true
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: "Sprawdzeń"
                                    font.pixelSize: 13
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Dobre
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            color: "#27ae60"
                            radius: 15
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 10
                                
                                Text {
                                    text: "✅"
                                    font.pixelSize: 40
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: currentSessionStats.good
                                    font.pixelSize: 28
                                    font.bold: true
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: "Dobrych"
                                    font.pixelSize: 13
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Złe
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            color: "#e74c3c"
                            radius: 15
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 10
                                
                                Text {
                                    text: "⚠️"
                                    font.pixelSize: 40
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: currentSessionStats.bad
                                    font.pixelSize: 28
                                    font.bold: true
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                
                                Text {
                                    text: "Złych"
                                    font.pixelSize: 13
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }

                    // Pasek postępu
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        color: "white"
                        border.color: "#ddd"
                        border.width: 2
                        radius: 15

                        // Używamy globalnej property currentSessionStats z głównego okna

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 15

                            RowLayout {
                                Layout.fillWidth: true
                                
                                Text {
                                    text: "Procent dobrych postaw"
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#2c3e50"
                                    Layout.fillWidth: true
                                }
                                
                                Text {
                                    text: "Śr. współczynnik: " + currentSessionStats.avg_coefficient
                                    font.pixelSize: 14
                                    color: "#7f8c8d"
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 40
                                    height: 60
                                    color: "#ecf0f1"
                                    radius: 30

                                    Rectangle {
                                        width: parent.width * (currentSessionStats.percentage / 100)
                                        height: parent.height
                                        color: currentSessionStats.percentage >= 70 ? "#27ae60" : 
                                               currentSessionStats.percentage >= 40 ? "#f39c12" : "#e74c3c"
                                        radius: 30

                                        Behavior on width {
                                            NumberAnimation { duration: 500 }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: currentSessionStats.percentage.toFixed(1) + "%"
                                        font.pixelSize: 24
                                        font.bold: true
                                        color: currentSessionStats.percentage > 50 ? "white" : "#2c3e50"
                                    }
                                }
                            }
                        }
                    }

                    // Wykres + Tabela obok siebie
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 400
                        spacing: 15

                        // Wykres
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "white"
                            border.color: "#ddd"
                            border.width: 2
                            radius: 15

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                Text {
                                    text: "📈 Współczynnik w czasie"
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#2c3e50"
                                }

                                Canvas {
                                    id: currentSessionCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)

                                        var checks = statisticsManager.get_current_session_checks()
                                        
                                        if (checks.length === 0) {
                                            ctx.fillStyle = "#95a5a6"
                                            ctx.font = "16px Arial"
                                            ctx.textAlign = "center"
                                            ctx.fillText("Brak danych - rozpocznij monitoring", width/2, height/2)
                                            return
                                        }

                                        var padding = 40
                                        var chartWidth = width - 2 * padding
                                        var chartHeight = height - 2 * padding

                                        // Osie
                                        ctx.strokeStyle = "#95a5a6"
                                        ctx.lineWidth = 2
                                        ctx.beginPath()
                                        ctx.moveTo(padding, padding)
                                        ctx.lineTo(padding, height - padding)
                                        ctx.lineTo(width - padding, height - padding)
                                        ctx.stroke()

                                        // Etykiety osi Y
                                        ctx.fillStyle = "#7f8c8d"
                                        ctx.font = "12px Arial"
                                        ctx.textAlign = "right"
                                        
                                        for (var i = 0; i <= 4; i++) {
                                            var val = (0.20 / 4) * i
                                            var y = height - padding - (chartHeight / 4) * i
                                            ctx.fillText(val.toFixed(2), padding - 10, y + 5)
                                            
                                            // Linie pomocnicze
                                            ctx.strokeStyle = "#ecf0f1"
                                            ctx.lineWidth = 1
                                            ctx.beginPath()
                                            ctx.moveTo(padding, y)
                                            ctx.lineTo(width - padding, y)
                                            ctx.stroke()
                                        }

                                        // Linia progu (0.20)
                                        var thresholdY = height - padding - (0.20 / 0.30) * chartHeight
                                        ctx.strokeStyle = "#f39c12"
                                        ctx.lineWidth = 2
                                        ctx.setLineDash([5, 5])
                                        ctx.beginPath()
                                        ctx.moveTo(padding, thresholdY)
                                        ctx.lineTo(width - padding, thresholdY)
                                        ctx.stroke()
                                        ctx.setLineDash([])

                                        // Linia danych
                                        if (checks.length > 1) {
                                            ctx.strokeStyle = "#3498db"
                                            ctx.lineWidth = 3
                                            ctx.beginPath()
                                            
                                            for (var i = 0; i < checks.length; i++) {
                                                if (!checks[i].detected) continue
                                                
                                                var x = padding + (i / Math.max(checks.length - 1, 1)) * chartWidth
                                                var coeff = Math.min(checks[i].coefficient, 0.20)
                                                var y = height - padding - (coeff / 0.30) * chartHeight
                                                
                                                if (i === 0) {
                                                    ctx.moveTo(x, y)
                                                } else {
                                                    ctx.lineTo(x, y)
                                                }
                                            }
                                            
                                            ctx.stroke()
                                        }

                                        // Punkty
                                        for (var i = 0; i < checks.length; i++) {
                                            if (!checks[i].detected) continue
                                            
                                            var x = padding + (i / Math.max(checks.length - 1, 1)) * chartWidth
                                            var coeff = Math.min(checks[i].coefficient, 0.20)
                                            var y = height - padding - (coeff / 0.30) * chartHeight
                                            
                                            ctx.fillStyle = checks[i].is_good ? "#27ae60" : "#e74c3c"
                                            ctx.beginPath()
                                            ctx.arc(x, y, 5, 0, 2 * Math.PI)
                                            ctx.fill()
                                        }
                                    }

                                    Connections {
                                        target: statisticsManager
                                        function onSessionDataChanged() {
                                            currentSessionCanvas.requestPaint()
                                        }
                                    }
                                }

                                Text {
                                    text: "🟢 Dobra postawa    🔴 Zła postawa    🟠 Próg (0.20)"
                                    font.pixelSize: 11
                                    color: "#7f8c8d"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Tabela sprawdzeń
                        Rectangle {
                            Layout.preferredWidth: 400
                            Layout.fillHeight: true
                            color: "white"
                            border.color: "#ddd"
                            border.width: 2
                            radius: 15

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                Text {
                                    text: "📋 Szczegóły sprawdzeń"
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#2c3e50"
                                }

                                // Nagłówek tabeli
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 40
                                    color: "#ecf0f1"
                                    radius: 8

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        Text {
                                            text: "Czas"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: "#2c3e50"
                                            Layout.preferredWidth: 70
                                        }

                                        Text {
                                            text: "Współcz."
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: "#2c3e50"
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "Status"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: "#2c3e50"
                                            Layout.preferredWidth: 80
                                        }
                                    }
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: 8

                                    model: statisticsManager.get_current_session_checks()

                                    delegate: Rectangle {
                                        width: ListView.view ? ListView.view.width : 0
                                        height: 45
                                        color: index % 2 === 0 ? "#f8f9fa" : "white"
                                        radius: 8

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            Text {
                                                text: modelData.time
                                                font.pixelSize: 11
                                                color: "#2c3e50"
                                                Layout.preferredWidth: 70
                                            }

                                            Text {
                                                text: modelData.coefficient.toFixed(3)
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: modelData.is_good ? "#27ae60" : "#e74c3c"
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 70
                                                Layout.preferredHeight: 25
                                                color: modelData.is_good ? "#27ae60" : "#e74c3c"
                                                radius: 5

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.is_good ? "✓ Dobra" : "✗ Zła"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: "white"
                                                }
                                            }
                                        }
                                    }

                                    ScrollBar.vertical: ScrollBar {}
                                }
                            }
                        }
                    }
                }
            }

            // ============================================
            // WIDOK 3: HISTORIA SESJI  
            // ============================================
            Rectangle {
                color: "#f0f0f0"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "📚 Historia sesji"
                            font.pixelSize: 28
                            font.bold: true
                            color: "#2c3e50"
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "🔄 Odśwież"
                            onClicked: {
                                sessionsListView.model = statisticsManager.get_all_sessions()
                            }
                        }
                    }

                    // Ogólne statystyki
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        color: "white"
                        border.color: "#ddd"
                        border.width: 2
                        radius: 15

                        property var overallStats: statisticsManager.get_overall_stats()

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 20

                            ColumnLayout {
                                spacing: 5
                                
                                Text {
                                    text: "🗂️ Sesji:"
                                    font.pixelSize: 12
                                    color: "#7f8c8d"
                                }
                                Text {
                                    text: parent.parent.parent.overallStats.session_count
                                    font.pixelSize: 24
                                    font.bold: true
                                    color: "#3498db"
                                }
                            }

                            Rectangle { width: 2; Layout.fillHeight: true; color: "#ecf0f1" }

                            ColumnLayout {
                                spacing: 5
                                
                                Text {
                                    text: "📊 Sprawdzeń:"
                                    font.pixelSize: 12
                                    color: "#7f8c8d"
                                }
                                Text {
                                    text: parent.parent.parent.overallStats.total_checks
                                    font.pixelSize: 24
                                    font.bold: true
                                    color: "#9b59b6"
                                }
                            }

                            Rectangle { width: 2; Layout.fillHeight: true; color: "#ecf0f1" }

                            ColumnLayout {
                                spacing: 5
                                
                                Text {
                                    text: "✅ % Dobrych:"
                                    font.pixelSize: 12
                                    color: "#7f8c8d"
                                }
                                Text {
                                    text: parent.parent.parent.overallStats.overall_percentage.toFixed(1) + "%"
                                    font.pixelSize: 24
                                    font.bold: true
                                    color: "#27ae60"
                                }
                            }

                            Rectangle { width: 2; Layout.fillHeight: true; color: "#ecf0f1" }

                            ColumnLayout {
                                spacing: 5
                                Layout.fillWidth: true
                                
                                Text {
                                    text: "⏱️ Łączny czas:"
                                    font.pixelSize: 12
                                    color: "#7f8c8d"
                                }
                                Text {
                                    text: parent.parent.parent.overallStats.total_hours.toFixed(1) + "h"
                                    font.pixelSize: 24
                                    font.bold: true
                                    color: "#e67e22"
                                }
                            }
                        }
                    }

                    // Lista sesji
                    ListView {
                        id: sessionsListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 15
                        clip: true
                        
                        model: statisticsManager.get_all_sessions()

                        delegate: Rectangle {
                            width: ListView.view ? ListView.view.width : 0
                            height: 140
                            color: "white"
                            border.color: "#ddd"
                            border.width: 2
                            radius: 15

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 20

                                // Ikona i data
                                ColumnLayout {
                                    spacing: 10
                                    Layout.preferredWidth: 150

                                    Text {
                                        text: "📅"
                                        font.pixelSize: 40
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: modelData.date
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#2c3e50"
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: modelData.time
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                Rectangle { width: 2; Layout.fillHeight: true; color: "#ecf0f1" }

                                // Statystyki
                                GridLayout {
                                    columns: 2
                                    rowSpacing: 10
                                    columnSpacing: 30
                                    Layout.fillWidth: true

                                    Text {
                                        text: "⏱️ Czas:"
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                    }
                                    Text {
                                        text: modelData.duration + " min"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#2c3e50"
                                    }

                                    Text {
                                        text: "📊 Sprawdzeń:"
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                    }
                                    Text {
                                        text: modelData.total_checks
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#2c3e50"
                                    }

                                    Text {
                                        text: "✅ Dobrych:"
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                    }
                                    Text {
                                        text: modelData.good_count + " (" + modelData.percentage + "%)"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#27ae60"
                                    }

                                    Text {
                                        text: "⚠️ Złych:"
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                    }
                                    Text {
                                        text: modelData.bad_count
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#e74c3c"
                                    }
                                }

                                // Akcje
                                ColumnLayout {
                                    spacing: 10
                                    Layout.preferredWidth: 120

                                    Button {
                                        text: "👁️ Zobacz"
                                        Layout.fillWidth: true
                                        onClicked: {
                                            sessionDetailsDialog.sessionId = modelData.id
                                            sessionDetailsDialog.sessionData = modelData
                                            sessionDetailsDialog.open()
                                        }
                                    }

                                    Button {
                                        text: "🗑️ Usuń"
                                        Layout.fillWidth: true
                                        onClicked: {
                                            statisticsManager.delete_session(modelData.id)
                                            sessionsListView.model = statisticsManager.get_all_sessions()
                                        }
                                    }
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {}
                    }
                }
            }

            // ============================================
            // WIDOK 4: PORÓWNANIE SESJI
            // ============================================
            ScrollView {
                clip: true
                
                ColumnLayout {
                    width: parent.parent.width - 20
                    spacing: 15
                    
                    Text {
                        text: "📈 Trend poprawy - Porównanie sesji"
                        font.pixelSize: 28
                        font.bold: true
                        color: "#2c3e50"
                        Layout.topMargin: 10
                    }

                    Text {
                        text: "Historyka ostatnich sesji z procentowym wskaźnikiem postawy"
                        font.pixelSize: 14
                        color: "#7f8c8d"
                    }

                    // Przycisk Export
                    Button {
                        text: "📊 Export wszystkie sesje do CSV"
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: 12
                        font.bold: true
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 40
                        
                        background: Rectangle {
                            color: parent.pressed ? "#16a085" : "#1abc9c"
                            radius: 8
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font: parent.font
                        }
                        
                        onClicked: {
                            var path = statisticsManager.export_all_sessions_csv()
                            exportSuccessNotification.message = "✅ Eksport wszystkich sesji:\n" + path
                            exportSuccessNotification.open()
                        }
                    }

                    // Tabela porównania
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"
                        border.color: "#ddd"
                        border.width: 2
                        radius: 15

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 10

                                // Nagłówek tabeli
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50
                                    spacing: 10

                                    Text {
                                        text: "Lp."
                                        font.bold: true
                                        color: "#2c3e50"
                                        Layout.preferredWidth: 30
                                    }

                                    Text {
                                        text: "Data"
                                        font.bold: true
                                        color: "#2c3e50"
                                        Layout.preferredWidth: 100
                                    }

                                    Text {
                                        text: "Czas"
                                        font.bold: true
                                        color: "#2c3e50"
                                        Layout.preferredWidth: 80
                                    }

                                    Text {
                                        text: "Sprawdzenia"
                                        font.bold: true
                                        color: "#2c3e50"
                                        Layout.preferredWidth: 100
                                    }

                                    Text {
                                        text: "% Dobra postawa"
                                        font.bold: true
                                        color: "#2c3e50"
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "Śr. współcz."
                                        font.bold: true
                                        color: "#2c3e50"
                                        Layout.preferredWidth: 100
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 2
                                    color: "#ecf0f1"
                                }

                                // Dane sesji
                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 5
                                    clip: true
                                    
                                    model: statisticsManager.get_comparison_data(10)

                                    delegate: Rectangle {
                                        width: ListView.view ? ListView.view.width : 0
                                        height: 50
                                        color: index % 2 === 0 ? "#f9f9f9" : "white"
                                        radius: 5

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            Text {
                                                text: (index + 1).toString()
                                                font.pixelSize: 12
                                                color: "#2c3e50"
                                                Layout.preferredWidth: 30
                                            }

                                            Text {
                                                text: modelData.date
                                                font.pixelSize: 12
                                                color: "#2c3e50"
                                                Layout.preferredWidth: 100
                                            }

                                            Text {
                                                text: modelData.time
                                                font.pixelSize: 12
                                                color: "#2c3e50"
                                                Layout.preferredWidth: 80
                                            }

                                            Text {
                                                text: modelData.total_checks
                                                font.pixelSize: 12
                                                color: "#2c3e50"
                                                Layout.preferredWidth: 100
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 10

                                                Rectangle {
                                                    Layout.preferredWidth: Math.max(modelData.percentage * 2, 20)
                                                    Layout.preferredHeight: 30
                                                    color: modelData.percentage >= 80 ? "#27ae60" :
                                                           modelData.percentage >= 60 ? "#f39c12" : "#e74c3c"
                                                    radius: 5

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.percentage + "%"
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: "white"
                                                    }
                                                }
                                            }

                                            Text {
                                                text: modelData.avg_coefficient.toFixed(3)
                                                font.pixelSize: 12
                                                color: "#2c3e50"
                                                Layout.preferredWidth: 100
                                            }
                                        }
                                    }

                                    ScrollBar.vertical: ScrollBar {}
                                }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {}
            }
        }
    }

    // Dialog szczegółów sesji
    Dialog {
        id: sessionDetailsDialog
        title: "📊 Szczegóły sesji"
        width: 900
        height: 600
        anchors.centerIn: parent
        modal: true

        property int sessionId: -1
        property var sessionData: ({})

        ColumnLayout {
            anchors.fill: parent
            spacing: 15

            // Nagłówek
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#3498db"
                radius: 10

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5

                    Text {
                        text: sessionDetailsDialog.sessionData.date + " " + sessionDetailsDialog.sessionData.time
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                    }

                    RowLayout {
                        spacing: 20

                        Text {
                            text: "⏱️ " + sessionDetailsDialog.sessionData.duration + " min"
                            font.pixelSize: 13
                            color: "white"
                        }

                        Text {
                            text: "📊 " + sessionDetailsDialog.sessionData.total_checks + " sprawdzeń"
                            font.pixelSize: 13
                            color: "white"
                        }

                        Text {
                            text: "✅ " + sessionDetailsDialog.sessionData.percentage + "%"
                            font.pixelSize: 13
                            color: "white"
                        }
                    }
                }
            }

            // Tabela szczegółów
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5

                model: sessionDetailsDialog.sessionId >= 0 ? 
                       statisticsManager.get_session_checks(sessionDetailsDialog.sessionId) : []

                delegate: Rectangle {
                    width: ListView.view ? ListView.view.width : 0
                    height: 40
                    color: index % 2 === 0 ? "#f8f9fa" : "white"
                    radius: 5

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        Text {
                            text: modelData.time
                            font.pixelSize: 12
                            color: "#2c3e50"
                            Layout.preferredWidth: 80
                        }

                        Text {
                            text: modelData.coefficient.toFixed(3)
                            font.pixelSize: 12
                            font.bold: true
                            color: modelData.is_good ? "#27ae60" : "#e74c3c"
                            Layout.preferredWidth: 80
                        }

                        Rectangle {
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 25
                            color: modelData.is_good ? "#27ae60" : "#e74c3c"
                            radius: 5

                            Text {
                                anchors.centerIn: parent
                                text: modelData.is_good ? "✓ Dobra postawa" : "✗ Zła postawa"
                                font.pixelSize: 10
                                font.bold: true
                                color: "white"
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                ScrollBar.vertical: ScrollBar {}
            }

            Button {
                text: "Zamknij"
                Layout.alignment: Qt.AlignRight
                onClicked: sessionDetailsDialog.close()
            }
        }
    }

    // Dialog ustawien
    Dialog {
        id: settingsDialog
        title: "Ustawienia"
        width: 500
        height: 650
        anchors.centerIn: parent
        modal: true

        property var availableCameras: []

        onOpened: {
            // Odśwież listę kamer przy otwieraniu dialogu
            availableCameras = postureMonitor.getAvailableCameras()
            cameraComboBox.model = availableCameras
            cameraComboBox.currentIndex = postureMonitor.getSelectedCamera()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 15

            // Sekcja kamery
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                color: "#e8f4fd"
                border.color: "#3498db"
                border.width: 1
                radius: 10

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "📷 Kamera"
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "🔄 Odśwież"
                            font.pixelSize: 11
                            onClicked: {
                                postureMonitor.refreshCameras()
                                settingsDialog.availableCameras = postureMonitor.getAvailableCameras()
                                cameraComboBox.model = settingsDialog.availableCameras
                            }
                        }
                    }

                    ComboBox {
                        id: cameraComboBox
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40

                        textRole: "name"
                        valueRole: "id"

                        onActivated: function(index) {
                            if (index >= 0 && settingsDialog.availableCameras.length > index) {
                                var cameraId = settingsDialog.availableCameras[index].id
                                postureMonitor.setSelectedCamera(cameraId)
                                console.log("Wybrano kamerę:", cameraId)
                            }
                        }
                    }

                    Text {
                        text: settingsDialog.availableCameras.length > 0 ?
                              "Rozdzielczość: " + (settingsDialog.availableCameras[cameraComboBox.currentIndex]?.resolution || "Nieznana") :
                              "Nie wykryto żadnych kamer"
                        font.pixelSize: 11
                        color: "#7f8c8d"
                    }

                    Text {
                        text: "Wskazówka: Jeśli kamera nie działa, kliknij Odśwież lub sprawdź czy nie jest używana przez inną aplikację."
                        font.pixelSize: 10
                        color: "#95a5a6"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Sekcja FPS podgladu
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: "#ecf0f1"
                radius: 10

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "🎬 FPS podgladu kamery"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        ComboBox {
                            id: fpsComboBox
                            Layout.fillWidth: true
                            model: [30, 20, 15, 10, 5, 2, 1]
                            currentIndex: 3  // Domyslnie 10 FPS

                            onActivated: function(index) {
                                postureMonitor.setPreviewFps(model[index])
                            }
                        }

                        Text {
                            text: "FPS"
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // Sekcja interwalu analizy
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: "#ecf0f1"
                radius: 10

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "📊 Interwal analizy postawy"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        SpinBox {
                            id: analysisIntervalSpinBox
                            from: 1
                            to: 60
                            value: 5
                            stepSize: 1
                            Layout.fillWidth: true

                            onValueChanged: {
                                postureMonitor.setAnalysisInterval(value)
                            }
                        }

                        Text {
                            text: "sekund"
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // Sekcja progu ostrzeżenia
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: "#ecf0f1"
                radius: 10

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "⚠️ Próg ostrzeżenia o złej postawie"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        SpinBox {
                            id: badPostureThresholdSpinBox
                            from: 5
                            to: 120
                            value: 30
                            stepSize: 5
                            Layout.fillWidth: true

                            onValueChanged: {
                                postureMonitor.setBadPostureThreshold(value)
                            }
                        }

                        Text {
                            text: "sekund"
                            font.pixelSize: 12
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Button {
                text: "✓ Zamknij"
                Layout.alignment: Qt.AlignRight
                onClicked: settingsDialog.close()
            }
        }
    }

    // Dialog sukcesu eksportu
    Dialog {
        id: exportSuccessNotification
        title: "✅ Eksport zakończony"
        width: 500
        height: 200
        anchors.centerIn: parent
        modal: true

        property string message: "Plik został zapisany"

        ColumnLayout {
            anchors.fill: parent
            spacing: 15

            Text {
                text: message
                font.pixelSize: 14
                color: "#27ae60"
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            Item { Layout.fillHeight: true }

            Button {
                text: "✓ OK"
                Layout.alignment: Qt.AlignRight
                onClicked: exportSuccessNotification.close()
            }
        }
    }

    // Pop-up ostrzeżenie o złej postawie
    Dialog {
        id: badPostureWarningDialog
        title: "⚠️ OSTRZEŻENIE - ZŁA POSTAWA"
        width: 500
        height: 250
        anchors.centerIn: parent
        modal: true

        property int durationSeconds: 0

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#fff3cd"
                border.color: "#ffc107"
                border.width: 2
                radius: 10

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "⚠️ UTRZYMUJESZ ZŁĄ POSTAWĘ!"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#856404"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Czas: " + badPostureWarningDialog.durationSeconds + " sekund"
                        font.pixelSize: 14
                        color: "#856404"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Text {
                text: "Twoja postawa jest zła przez dłuższy czas. Prostuj się i wyprostuj plecy!"
                font.pixelSize: 13
                color: "#333333"
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "🔕 Nie pokazuj więcej"
                    Layout.preferredWidth: 160

                    background: Rectangle {
                        color: parent.pressed ? "#6c757d" : "#adb5bd"
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        mutePostureWarnings = true
                        badPostureWarningDialog.close()
                        console.log("Ostrzeżenia o złej postawie wyciszone")
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "✓ OK"
                    Layout.preferredWidth: 100

                    background: Rectangle {
                        color: parent.pressed ? "#1e7e34" : "#28a745"
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: badPostureWarningDialog.close()
                }
            }
        }
    }
    
    Component.onCompleted: {
        console.log("============================================================")
        console.log("Monitor Postawy z rozbudowanymi statystykami")
        console.log("============================================================")
    }
}
