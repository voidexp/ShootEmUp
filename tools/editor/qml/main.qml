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

            // Left panel
            Item {
                id: leftPanel
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            // Map canvas
            Canvas {
                id: editorCanvas
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width > parent.height ? parent.height : parent.width * 0.6

                onPaint: {
                    var ctx = getContext("2d");
                    const size = Math.min(width, height);
                    const x0 = (width - size) / 2;
                    const y0 = (height - size) / 2;

                    /* Draw the background */
                    ctx.fillStyle = Style.bg;
                    ctx.fillRect(x0, y0, size, size);

                    /* Draw the grid */
                    ctx.strokeStyle = Style.fg;
                    ctx.lineWidth = 0.5;
                    const cells = 32;
                    var step = 1.0 / cells * size;
                    for (var c = 0; c < cells; c++) {
                        ctx.beginPath();
                        ctx.moveTo(x0 + c * step, y0);
                        ctx.lineTo(x0 + c * step, y0 + size);
                        ctx.stroke();

                        ctx.beginPath();
                        ctx.moveTo(x0, y0 + c * step);
                        ctx.lineTo(x0 + size, y0 + c * step);
                        ctx.stroke();
                    }
                    ctx.rect(x0, y0, size, size);
                    ctx.stroke();
                }
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
