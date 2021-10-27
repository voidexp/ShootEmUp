import QtQuick 2.0
import Editor 1.0

GridView {
    id: gridView

    signal objectSelected(GameObject object)

    cellWidth: 32
    cellHeight: cellWidth
    currentIndex: -1
    delegate: objectDelegate

    Component {
        id: objectDelegate

        Rectangle {
            property bool hovered: false
            property bool pressed: false

            width: gridView.cellWidth - 2
            height: gridView.cellHeight - 2

            color: Style.bg;
            border.color: {
                if (pressed) {
                    return Style.hi
                }

                if (GridView.isCurrentItem || hovered) {
                    return Style.lo;
                }

                return Style.bg;
            }
            border.width: 1

            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                onClicked: {
                    gridView.currentIndex = index
                    gridView.objectSelected(gridView.model[index])
                }
                onEntered: {
                    tooltip.visible = true
                    parent.hovered = true
                }
                onExited: {
                    tooltip.visible = false
                    parent.hovered = false
                }
                onPressed: parent.pressed = true
                onReleased: parent.pressed = false

                Rectangle {
                    id: tooltip
                    visible: false
                    radius: 3
                    color: Style.lo
                    width: Math.max(tooltipLabel.contentWidth + 10, parent.width)
                    height: tooltipLabel.contentHeight + 4
                    anchors.bottom: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: {
                        top: 2
                    }

                    Text {
                        id: tooltipLabel
                        text: modelData.name
                        color: Style.hi
                        anchors.centerIn: parent
                    }
                }
            }

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: "image://gameObjects/" + modelData.name
                smooth: false
            }
        }
    }
}
