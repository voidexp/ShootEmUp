import QtQuick 2.0
import QtQuick.Layouts 1.3
import Editor 1.0


Canvas {
    id: canvas
    property vector2d cursor: Qt.vector2d(-1, -1)
    property GameObject brush: null

    /* private stuff */
    property string brushImage
    property var objects: []

    readonly property real tileSize: 8
    readonly property real gridCells: 32
    property real gridSize
    property real gridStep
    property real gridX
    property real gridY

    Component.onCompleted: redrawGrid();

    function redrawGrid() {
        gridSize = Math.min(width, height);
        gridStep = 1.0 / gridCells * gridSize;
        gridX = (width - gridSize) / 2;
        gridY = (height - gridSize) / 2;
        markDirty(Qt.rect(0, 0, width, height));
    }

    onBrushChanged: {
        brushImage = brush ? ("image://gameObjects/" + brush.name) : '';
        if (brush) {
            loadImage(brushImage);
        }
        redrawGrid();
    }

    onObjectsChanged: redrawGrid();

    onWidthChanged: redrawGrid();

    onHeightChanged: redrawGrid();

    onPaint: {
        var ctx = getContext("2d");

        /* Draw the background */
        ctx.fillStyle = Style.bg;
        ctx.fillRect(gridX, gridY, gridSize, gridSize);

        /* Draw the grid */
        ctx.strokeStyle = Style.fg;
        ctx.lineWidth = 0.5;
        for (var c = 0; c < gridCells; c++) {
            ctx.beginPath();
            ctx.moveTo(gridX + c * gridStep, gridY);
            ctx.lineTo(gridX + c * gridStep, gridY + gridSize);
            ctx.stroke();

            ctx.beginPath();
            ctx.moveTo(gridX, gridY + c * gridStep);
            ctx.lineTo(gridX + gridSize, gridY + c * gridStep);
            ctx.stroke();
        }
        ctx.rect(gridX, gridY, gridSize, gridSize);
        ctx.stroke();

        /* Draw the foreground objects */
        for (var i = 0; i < objects.length; i++) {
            const object = objects[i];
            const proto = object.prototype;
            const image = "image://gameObjects/" + proto.name;
            if (isImageLoaded(image)) {
                const scaleFactor = (1.0 / tileSize) * gridStep;
                ctx.drawImage(
                    image,
                    gridX + object.position.x * scaleFactor,
                    gridY + object.position.y * scaleFactor,
                    proto.rect.width * scaleFactor,
                    proto.rect.height * scaleFactor
                );
            }
        }

        /* Draw the brush */
        if (brush && cursor.x >= gridX && cursor.y >= gridY && cursor.y <= width - gridX && cursor.y <= height - gridY) {
            const col = Math.floor((cursor.x - gridX) / gridStep);
            const row = Math.floor((cursor.y - gridY) / gridStep);
            const brushWidth = gridStep * (brush.rect.width / tileSize);
            const brushHeight = gridStep * (brush.rect.height / tileSize);
            const brushX = gridX + col * gridStep;
            const brushY = gridY + row * gridStep;

            if (isImageLoaded(brushImage)) {
                ctx.drawImage(brushImage, brushX, brushY, brushWidth, brushHeight);
            }

            ctx.beginPath();
            ctx.strokeStyle = Style.lo;
            ctx.rect(brushX, brushY, brushWidth, brushHeight);
            ctx.stroke();
        }
    }

    onCursorChanged: {
        markDirty(Qt.rect(0, 0, width, height));
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        onPositionChanged: function (mouse) {
            parent.cursor = Qt.vector2d(mouse.x, mouse.y);
        }

        onExited: {
            parent.cursor = Qt.vector2d(-1, -1); // special invalid vector
        }

        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                canvas.brush = null;
            } else {
                const col = Math.floor((mouse.x - gridX) / gridStep);
                const row = Math.floor((mouse.y - gridY) / gridStep);
                const x = col * tileSize;
                const y = row * tileSize;

                var inst = Qt.createQmlObject(`
                    import Editor 1.0
                    GameObjectInstance {
                        prototype: {prototype = canvas.brush;}
                        position: Qt.point(${x}, ${y})
                    }
                `, canvas);
                console.log(inst, inst.prototype, inst.position, inst.prototype.name, inst.prototype.rect);
                canvas.objects.push(inst);
                canvas.objects = [...canvas.objects];
            }
        }
    }
}
