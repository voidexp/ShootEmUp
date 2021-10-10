import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Window {
    width: 640
    height: 600
    visible: true
    title: qsTr("ShootEmUp level editor")

    Canvas {
        id: editorCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.fillStyle = Qt.black;
            ctx.strokeStyle = Qt.rgba(0.3, 0.3, 0.3, 1.0);
            ctx.lineWidth = 0.5;
            ctx.fillRect(0, 0, width, height);

            var step = 1.0 / 32 * width;

            for (var c = 0; c < 32; c++) {
                ctx.beginPath();
                ctx.moveTo(c * step, 0);
                ctx.lineTo(c * step, height);
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(0, c * step);
                ctx.lineTo(width, c * step);
                ctx.stroke();
            }
        }
    }
}
