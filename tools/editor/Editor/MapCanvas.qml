import QtQuick 2.0
import QtQuick.Layouts 1.3
import Editor 1.0


Canvas {
    id: canvas
    // Mouse cursor position in world coords
    property point cursor: Qt.point(-1, -1)

    // Active game object to be used as brush
    property GameObject brush: null

    /* PRIVATE STUFF */
    property string brushImage
    property var objects: []
    readonly property real tileSize: 8
    readonly property real tiles: 32
    property real gridSize
    property real gridStep
    property real gridScale
    property real gridX
    property real gridY

    function repaint() {
        gridSize = Math.min(width, height);
        gridStep = 1.0 / tiles * gridSize;
        gridScale = (1.0 / tileSize) * gridStep
        gridX = (width - gridSize) / 2;
        gridY = (height - gridSize) / 2;
        markDirty(Qt.rect(0, 0, width, height));
    }

    /* Add an instance of current brush game object at current cursor */
    function addObject() {
        // snap the coords to "world grid"
        const x = Math.floor(cursor.x / tileSize) * tileSize;
        const y = Math.floor(cursor.y / tileSize) * tileSize;

        var obj = Qt.createQmlObject(`
            import Editor 1.0
            GameObjectInstance {
                prototype: {prototype = brush;}
                position: Qt.point(${x}, ${y})
            }
        `, canvas);
        console.log("Adding", obj, obj.prototype.name, obj.position);
        canvas.objects.push(obj);
        canvas.objects = [...canvas.objects];
    }

    /* Remove an object at current cursor */
    function removeObject() {
        const i = objectIndexAt(cursor.x, cursor.y);
        if (i !== -1) {
            const obj = objects[i];
            console.log("Removing", obj, obj.prototype.name, obj.position);
            objects.splice(i, 1);
            objects = [...objects];
        }
    }

    /* Retrieve the index of the top-most object at given world coords */
    function objectIndexAt(x, y) {
        for (var i = objects.length - 1; i >= 0; i--) {
            const obj = objects[i];
            const top = obj.position.y;
            const bottom = obj.position.y + obj.prototype.rect.height;
            const left = obj.position.x;
            const right = obj.position.x + obj.prototype.rect.width;
            if (x >= left && x <= right && y >= top && y <= bottom) {
                return i;
            }
        }
        return -1;
    }

    onBrushChanged: {
        brushImage = brush ? ("image://gameObjects/" + brush.name) : '';
        if (brush) {
            loadImage(brushImage);
        }
        repaint();
    }

    onObjectsChanged: repaint()

    onWidthChanged: repaint()

    onHeightChanged: repaint()

    onCursorChanged: repaint()

    Component.onCompleted: repaint()

    onPaint: {
        var ctx = getContext("2d");

        // cursor position in view coordinates
        const x = Math.floor(cursor.x / tileSize) * gridStep + gridX;
        const y = Math.floor(cursor.y / tileSize) * gridStep + gridY;

        /* Draw the background */
        ctx.fillStyle = Style.bg;
        ctx.fillRect(gridX, gridY, gridSize, gridSize);

        /* Draw the grid */
        ctx.strokeStyle = Style.fg;
        ctx.lineWidth = 0.5;
        for (var c = 0; c < tiles; c++) {
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
            const x0 = gridX + object.position.x * gridScale;
            const y0 = gridY + object.position.y * gridScale;
            const w = proto.rect.width * gridScale;
            const h = proto.rect.height * gridScale;
            var isHovered = !brush && x >= x0 && x <= x0 + w && y >= y0 && y <= y0 + h;

            // draw the object image
            if (isImageLoaded(image)) {
                ctx.drawImage(image, x0, y0, w, h);
            }

            // highlight the object if it's hovered onto and there's no active brush
            if (!brush && isHovered) {
                ctx.beginPath();
                ctx.strokeStyle = Style.lo;
                ctx.rect(x0, y0, w, h);
                ctx.stroke();
            }
        }

        /* Draw the brush */
        if (brush && cursor.x >= 0 && cursor.y >= 0) {
            const brushWidth = gridStep * (brush.rect.width / tileSize);
            const brushHeight = gridStep * (brush.rect.height / tileSize);

            // draw the object image
            if (isImageLoaded(brushImage)) {
                ctx.drawImage(brushImage, x, y, brushWidth, brushHeight);
            }

            // draw the outline
            ctx.beginPath();
            ctx.strokeStyle = Style.lo;
            ctx.rect(x, y, brushWidth, brushHeight);
            ctx.stroke();
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        function toWorldCoords(x, y) {
            const scaleFactor = 1.0 / canvas.gridSize * (canvas.tileSize * canvas.tiles);
            const col = Math.floor((x - canvas.gridX) / canvas.gridStep);
            const row = Math.floor((y - canvas.gridY) / canvas.gridStep);
            const worldX = (x - canvas.gridX) * scaleFactor;
            const worldY = (y - canvas.gridY) * scaleFactor;
            return Qt.point(Math.floor(worldX), Math.floor(worldY));
        }

        onPositionChanged: function (mouse) {
            parent.cursor = toWorldCoords(mouse.x, mouse.y);
        }

        onExited: {
            parent.cursor = Qt.point(-1, -1); // special invalid point
        }

        onClicked: function (mouse) {
            parent.cursor = toWorldCoords(mouse.x, mouse.y);
            if (mouse.button === Qt.RightButton) {
                if (canvas.brush) {
                    canvas.brush = null;
                } else {
                    removeObject();
                }
            } else if (mouse.button === Qt.LeftButton) {
                if (canvas.brush) {
                    addObject();
                } else {
                    // todo
                }
            }
        }
    }
}
