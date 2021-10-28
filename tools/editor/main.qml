import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Dialogs

import Editor 1.0

import "Editor"
import "Editor/Controls"

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

            Button {
                icon: Style.icons.folderOpen
                onClicked: {
                    fileDialog.fileMode = FileDialog.OpenFile;
                    fileDialog.open();
                }
            }

            Button {
                icon: Style.icons.save
                onClicked: {
                    fileDialog.fileMode = FileDialog.SaveFile;
                    fileDialog.open();
                }
            }
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
                levelData: levelData
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

    FileDialog {
        id: fileDialog
        nameFilters: ["Level files (*.yaml)"]
        onAccepted: {
            if (fileMode === FileDialog.SaveFile) {
                console.log("saving level to", selectedFile)
                levelData.save(selectedFile);
            } else if (fileMode === FileDialog.OpenFile) {
                console.log("loading level from", selectedFile);
                levelData.load(selectedFile);
            }
        }
    }

    LevelData {
        id: levelData
    }
}
