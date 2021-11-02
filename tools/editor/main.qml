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
    title: qsTr("Shoot'em Up Editor") + " - " + fileDialog.selectedFile || "<new level>"

    color: Style.bg

    Column {
        anchors.fill: parent
        anchors.margins: 5

        // Toolbar
        Row {
            id: toolbar

            Button {
                icon: Style.icons.file
                onClicked: levelData.clear()
            }

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
            width: parent.width
            height: parent.height - toolbar.height
            Layout.alignment: Qt.AlignLeft

            // Left panel - objects
            ObjectsPanel {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.24
                model: gameObjects

                onObjectSelected: function (object) {
                    mapCanvas.brush = object;
                }
            }

            Row {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // Map canvas
                MapCanvas {
                    id: mapCanvas
                    levelData: levelData
                    width: parent.height
                    height: parent.height
                }

                // Map scroller widget
                ColumnLayout {
                    id: scrollerPanel
                    width: mapCanvas.width * 0.1
                    height: parent.height

                    ListView {
                        id: mapScrollerView
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        model: levelData
                        verticalLayoutDirection: ListView.VerticalBottomToTop
                        clip: true

                        onCurrentIndexChanged: mapCanvas.currentStageIndex = currentIndex

                        delegate: Rectangle {
                            width: mapScrollerView.width
                            height: width
                            color: "black"
                            border.color: ListView.isCurrentItem ? Style.fg : Style.bg
                            border.width: 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: mapScrollerView.currentIndex = index
                            }

                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Button {
                            icon: Style.icons.add
                            onClicked: levelData.addNewStage()
                        }

                        Button {
                            icon: Style.icons.remove
                            enabled: levelData.size > 1
                            onClicked: levelData.removeStage(mapScrollerView.currentIndex)
                        }
                    }
                }
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
