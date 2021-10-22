import QtQuick 2.0

import ".."

Rectangle {
    property alias icon: iconText.text
    width: height
    height: parent.height - 2
    color: Style.bg
    border.color: area.containsMouse ? (area.pressed ? Style.hi : Style.lo) : Style.bg
    border.width: 1

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true

        Text {
            id: iconText
            anchors.centerIn: parent
            font.family: Style.iconFont.name
            font.pointSize: Style.iconSize
            color: area.pressed ? Style.hi : Style.lo
        }
    }
}
