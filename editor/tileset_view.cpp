#include "tileset_view.h"
#include "state.h"
#include <QGraphicsItem>
#include <QMouseEvent>

const float scaleFactor = 2.0;
const float size = 128 * scaleFactor + 10;

TilesetView::TilesetView(QWidget *parent)
    : QGraphicsView(parent)
{
    setBackgroundBrush(QBrush(Qt::black));
    scale(scaleFactor, scaleFactor);
    setFixedSize(::size, ::size);

    // Listen for tool changes
    connect(State::get(), &State::activeToolChanged, this, [=](State::Tool tool){
        // enable mouse tracking for new brush select
        setMouseTracking(tool == State::Tool::BRUSH);

        viewport()->repaint();
    });
}

void TilesetView::drawForeground(QPainter *painter, const QRectF &rect)
{
    QGraphicsView::drawForeground(painter, rect);

    auto state = State::get();
    auto tile = state->getBrush()->getTile();

    if (state->getActiveTool() == State::Tool::BRUSH
        && items().length() > tile)
    {
        // Draw secondary highlight rect around the hovered tile item, if any found
        // under last mouse cursor position
        auto hoveredItem = itemAt(cursorPos);
        if (hoveredItem)
        {
            painter->setPen(QPen(QBrush(Qt::yellow), 1.0 / scaleFactor));
            painter->drawRect(hoveredItem->x() - 1, hoveredItem->y() - 1, 8, 8);
        }

        // Draw primary highlight rect around the active tile item.
        // The tile index is used as the index of the graphics item in the scene.
        // Since items are listed in descending stacking order, reverse index is computed.
        // See https://doc.qt.io/qt-6/qgraphicsview.html#items
        auto item = items().at(items().length() - 1 - tile);
        painter->setPen(QPen(QBrush(Qt::green), 1.0 / scaleFactor));
        painter->drawRect(item->x() - 1, item->y() - 1, 8, 8);
    }
}

void TilesetView::mouseMoveEvent(QMouseEvent *event)
{
    cursorPos = event->pos();
    viewport()->repaint();
}

void TilesetView::mouseReleaseEvent(QMouseEvent *event)
{
    if (event->button() == Qt::MouseButton::LeftButton)
    {
        auto item = itemAt(event->pos());
        if (item)
        {
            emit tileSelected(item->data(DataKey::TILE_INDEX).value<int>());
            viewport()->repaint();
        }
    }
}
