import QtQuick 2.12
import QtQuick.Window

import "Controls"

Window {
    minimumWidth: 600
    minimumHeight: 800
    visible: true
    title: qsTr("Level Editor")

    color: Style.bg

    Column {
        anchors.fill: parent

        Row {
            Button { icon: Style.icons.file }
            Button { icon: Style.icons.folderOpen }
            Button { icon: Style.icons.save }
        }

        Canvas {
            id: editorCanvas
            width: Math.min(parent.width, parent.height)
            height: width
            onPaint: {
                var ctx = getContext("2d");

                /* Draw the background */
                ctx.fillStyle = Style.bg;
                ctx.fillRect(0, 0, width, height);

                /* Draw the grid */
                ctx.strokeStyle = Style.fg;
                ctx.lineWidth = 0.5;
                var size = width;
                const cells = 32;
                var step = 1.0 / cells * size;
                for (var c = 0; c < cells; c++) {
                    ctx.beginPath();
                    ctx.moveTo(c * step, 0);
                    ctx.lineTo(c * step, size);
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.moveTo(0, c * step);
                    ctx.lineTo(size, c * step);
                    ctx.stroke();
                }
                ctx.beginPath();
                ctx.rect(0, 0, size, size);
                ctx.stroke();
            }
        }
    }

}
