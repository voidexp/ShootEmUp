import QtQuick 2.0
import QtQuick.Layouts 1.3

Canvas {
    property vector2d cursor: Qt.vector2d(-1, -1)

    onPaint: {
        var ctx = getContext("2d");
        const size = Math.min(width, height);
        const x0 = (width - size) / 2;
        const y0 = (height - size) / 2;
        const cells = 32;
        var step = 1.0 / cells * size;

        /* Draw the background */
        ctx.fillStyle = Style.bg;
        ctx.fillRect(x0, y0, size, size);

        /* Draw the grid */
        ctx.strokeStyle = Style.fg;
        ctx.lineWidth = 0.5;
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

        /* Highlight the hovered cell */
        if (cursor.x >= x0 && cursor.y >= y0 && cursor.y <= width - x0 && cursor.y <= height - y0) {
            ctx.beginPath();
            const col = Math.floor((cursor.x - x0) / step);
            const row = Math.floor((cursor.y - y0) / step);
            ctx.strokeStyle = Style.lo;
            ctx.rect(x0 + col * step, y0 + row * step, step, step);
            ctx.stroke();
        }
    }

    onCursorChanged: {
        markDirty(Qt.rect(0, 0, width, height));
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onPositionChanged: function (mouse) {
            parent.cursor = Qt.vector2d(mouse.x, mouse.y);
        }

        onExited: {
            parent.cursor = Qt.vector2d(-1, -1); // special invalid vector
        }
    }
}
