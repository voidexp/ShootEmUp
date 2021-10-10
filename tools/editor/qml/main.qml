import QtQuick 2.0
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts


Window {
    width: 800
    height: 800
    visible: true
    title: qsTr("Level Editor")

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
        }
    }
}
