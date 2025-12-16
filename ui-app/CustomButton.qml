import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3


Button {
    id:control

    implicitWidth: Math.max(46, contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding

    leftPadding: 0
    rightPadding: 16
    topPadding: 12
    bottomPadding: 12

    property real radius: 8
    property color backgroundColor: "#14A44D"
    property string setIcon: ""
    property color textColor: "#666666"

    property real borderWidth: 0
    property color borderColor: "transparent"
    font.pixelSize: FontStyle.h3
    font.family: "Roboto"

    contentItem:RowLayout{
        width: parent.width
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: control.font.pixelSize * 0.5
        Image{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            visible: control.setIcon !== ""
            property int size: control.font.pixelSize * 1.5
            sourceSize: Qt.size(size, size)
            source: setIcon
            fillMode: Image.PreserveAspectFit
        }
        Label {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            visible: control.text !== ""
            font: control.font
            text: control.text
            color: control.textColor
        }
    }

    background: Rectangle{
        implicitHeight: control.implicitHeight
        implicitWidth: control.implicitWidth
        radius: control.radius
        color: control.backgroundColor
        border.width: control.borderWidth
        border.color: control.borderColor

        visible: false

        Behavior on color {

            ColorAnimation {
                easing.type: Easing.Linear
                duration: 200
            }
        }

        Rectangle{
            id:indicator
            property int mx
            property int my
            x:mx-width/2
            y:my-height/2
            height:width
            radius: control.radius
            color: Qt.lighter(AppStyle.appStyle)
        }
    }

    Rectangle{
        id:mask
        radius: control.radius
        anchors.fill: parent
        visible: false
    }

    MouseArea{
        id:mouseArea
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
    }

    ParallelAnimation{
        id:main
        NumberAnimation{
            target: indicator
            properties: 'width'
            from:0
            to:control.width *2.5
            duration: 200
        }
        NumberAnimation{
            target: indicator
            properties: 'opacity'
            from:0.9
            to:0
            duration: 200
        }
    }

    onPressed: {
        indicator.mx = mouseArea.mouseX
        indicator.my = mouseArea.mouseY
        main.restart()
    }
}
