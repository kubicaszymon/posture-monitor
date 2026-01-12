import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control

    implicitWidth: Math.max(46, contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding

    leftPadding: 10
    rightPadding: 16
    topPadding: 12
    bottomPadding: 12

    property real radius: 8
    property color backgroundColor: "#14A44D"
    property string setIcon: ""
    property color textColor: "#FFFFFF"
    property real borderWidth: 0
    property color borderColor: "transparent"

    font.pixelSize: 14
    font.family: "Roboto"

    contentItem: RowLayout {
        spacing: control.font.pixelSize * 0.5
        
        Image {
            Layout.alignment: Qt.AlignVCenter
            visible: control.setIcon !== ""
            Layout.preferredWidth: control.font.pixelSize * 1.5
            Layout.preferredHeight: control.font.pixelSize * 1.5
            source: setIcon
            fillMode: Image.PreserveAspectFit
        }
        
        Label {
            Layout.alignment: Qt.AlignVCenter
            visible: control.text !== ""
            font: control.font
            text: control.text
            color: control.textColor
        }
    }

    background: Rectangle {
        implicitHeight: control.implicitHeight
        implicitWidth: control.implicitWidth
        radius: control.radius
        color: control.hovered ? Qt.lighter(control.backgroundColor, 1.1) : control.backgroundColor
        border.width: control.borderWidth
        border.color: control.borderColor

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        // Efekt ripple
        Rectangle {
            id: ripple
            property int mx
            property int my
            x: mx - width / 2
            y: my - height / 2
            height: width
            radius: width / 2
            opacity: 0
            color: Qt.lighter(control.backgroundColor, 1.3)
        }
    }

    MouseArea {
        id: mouseArea
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
    }

    ParallelAnimation {
        id: rippleAnimation
        NumberAnimation {
            target: ripple
            property: "width"
            from: 0
            to: control.width * 2.5
            duration: 400
        }
        NumberAnimation {
            target: ripple
            property: "opacity"
            from: 0.6
            to: 0
            duration: 400
        }
    }

    onPressed: {
        ripple.mx = mouseArea.mouseX
        ripple.my = mouseArea.mouseY
        rippleAnimation.restart()
    }
}
