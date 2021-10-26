import QtQuick 2.12
import QtQuick.Window
import QtQuick.Layouts

import "Controls"

Window {
    minimumWidth: 1200
    minimumHeight: 680
    visible: true
    title: qsTr("Level Editor")

    color: Style.bg

    ColumnLayout {
        anchors.fill: parent

        // Toolbar
        RowLayout {
            id: toolbar
            Layout.fillWidth: true
            height: 50;

            Button { icon: Style.icons.file }
            Button { icon: Style.icons.folderOpen }
            Button { icon: Style.icons.save }
        }

        // Main area
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            // Left panel - objects
            ObjectsPanel {
                Layout.fillHeight: true
                Layout.fillWidth: true
                model: gameObjects

                onObjectSelected: function (object) {
                    mapCanvas.brush = object;
                }
            }

            // Map canvas
            MapCanvas {
                id: mapCanvas
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width > parent.height ? parent.height : parent.width * 0.6
            }

            // Right panel
            Item {
                id: rightPanel
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }

}
