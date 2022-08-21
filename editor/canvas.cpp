#include "canvas.h"
#include "state.h"

#include <QMouseEvent>
#include <QGraphicsPixmapItem>

const float scaleFactor = 4.0;

Canvas::Canvas(QWidget *parent)
    : QGraphicsView{parent}
    , bgBrush(QBrush(QPixmap(":/icons/no-tile.png")))
{
    scale(scaleFactor, scaleFactor);
    setMouseTracking(true);
}

void Canvas::drawForeground(QPainter *painter, const QRectF &rect)
{
    QRectF bounds = scene()->sceneRect();
    auto state = State::get();

    // draw the grid
    painter->setPen(QPen(QBrush(Qt::darkGray), 1.0 / scaleFactor));
    for (int row = 1; row < abs(bounds.height() / 8); row++)
    {
        for (int col = 1; col < bounds.width() / 8; col++)
        {
            float x = col * 8;
            float y = bounds.y() - row * 8;
            const float size = 0.5;
            painter->drawLine(QPointF(x, y), QPointF(x, y + size));
            painter->drawLine(QPointF(x, y), QPointF(x, y - size));
            painter->drawLine(QPointF(x, y), QPointF(x + size, y));
            painter->drawLine(QPointF(x, y), QPointF(x - size, y));
        }
    }

    // draw the active brush, if any
    if (state->getActiveTool() == State::Tool::BRUSH
        && state->getTileset()->valid())
    {
        // clamp the mouse coords to the 8x8 grid and normalize
        auto pos = sceneToLevel(mapToScene(cursorPos));

        if (pos.x() >= 0 and pos.y() >= 0 and pos.x() < 32 and pos.y() < 30)
        {
            auto tileID = state->getBrush()->getTile();
            auto tilePixmap = (*state->getTileset())[tileID];
            painter->drawPixmap(levelToScene(pos), tilePixmap);
        }
    }
}

void Canvas::drawBackground(QPainter *painter, const QRectF &rect)
{
    QRectF bounds = scene()->sceneRect();

    // draw the no-tile background pattern
    painter->fillRect(bounds, Qt::black);
    painter->setOpacity(0.4);
    painter->fillRect(bounds, QBrush(Qt::gray, Qt::BrushStyle::BDiagPattern));
    painter->fillRect(bounds, bgBrush);

    // erase the background pattern at places occupied by items
    painter->setOpacity(1.0);
    for (auto item : scene()->items())
    {
        painter->fillRect(item->x(), item->y(), 8, 8, Qt::black);
    }
}

void Canvas::mouseMoveEvent(QMouseEvent *event)
{
    cursorPos = event->pos();
    viewport()->repaint();
}

void Canvas::mouseReleaseEvent(QMouseEvent *event)
{
    auto state = State::get();

    // On left click with an active brush, add a new item to the scene
    if (event->button() == Qt::MouseButton::LeftButton
        && state->getActiveTool() == State::Tool::BRUSH
        && state->getTileset()->valid())
    {
        // get the tile ID of the current brush and its associated pixmap
        auto tileID = state->getBrush()->getTile();
        auto tilePixmap = (*state->getTileset())[tileID];

        // add the pixmap to the scene
        auto item = scene()->addPixmap(tilePixmap);
        auto pos = sceneToLevel(mapToScene(event->pos()));
        auto scenePos = levelToScene(pos);
        item->setPos(scenePos);

        // store the tile ID in pixmap item's data
        item->setData(DataKey::TILE_INDEX, QVariant::fromValue(tileID));

        qDebug() << "Painting" << tileID << "at" << pos;
    }
}

QPointF Canvas::sceneToLevel(const QPointF &point)
{
    return QPointF(floor(point.x() / 8), 30 + floor(point.y() / 8));
}

QPointF Canvas::levelToScene(const QPointF &point)
{
    return QPointF(point.x() * 8, -30 * 8 + point.y() * 8);
}
