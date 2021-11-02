import QtQuick 2.0
import Editor 1.0

Rectangle {
    property alias icon: iconText.text
    property bool enabled: true

    signal clicked

    implicitWidth: 50
    implicitHeight: 50
    color: Style.bg
    border.color: {
        if (enabled) {
            return area.containsMouse ? (area.pressed ? Style.hi : Style.lo) : Style.bg;
        }
        return Style.bg;
    }
    border.width: 1

    Text {
        id: iconText
        anchors.centerIn: parent
        font.family: Style.iconFont.name
        font.pointSize: Style.iconSize
        color: {
            if (parent.enabled) {
                return area.pressed ? Style.hi : Style.lo;
            }
            return Style.fg;
        }
    }

    MouseArea {
        id: area
        enabled: parent.enabled
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }
}
