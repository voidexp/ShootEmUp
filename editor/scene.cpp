#include "scene.h"
#include "state.h"

#include <QGraphicsPixmapItem>

Scene::Scene(QObject *parent)
    : QGraphicsScene{parent}
{
    // initial size -> one screen; screens grow to negative Y (up)
    setSceneRect(0, 0, 32*8, -30*8);

    auto level = State::get()->level();

    // react to level changes
    connect(level, &Level::tilesChanged, this, &Scene::updateTiles);
}

void Scene::addTileAt(const QPoint &loc, int id)
{
    auto currentTile = getTileAt(loc);
    if (currentTile != -1)
    {
        removeTileAt(loc);
    }

    QPixmap pixmap = (*State::get()->getTileset())[id];
    auto item = addPixmap(pixmap);

    item->setPos(loc);
}

void Scene::removeTileAt(const QPoint &loc)
{
    auto item = itemAt(loc, QTransform{});
    if (!item)
    {
        return;
    }

    auto data = item->data(DataKey::TILE_INDEX);
    if (!data.isValid() || data.value<int>() == -1)
    {
        return;
    }

    removeItem(item);
}

int Scene::getTileAt(const QPoint &loc) const
{
    auto item = itemAt(loc, QTransform{});
    if (item)
    {
        auto tileID = item->data(DataKey::TILE_INDEX).value<int>();
        return tileID;
    }
    return -1;
}


void Scene::updateTiles(const TileData &tiles)
{
    auto state = State::get();

    for (auto& [coord, tile]: tiles)
    {
        auto scenePos = mapFromLevel(QPoint(coord.col, coord.row));

        // remove any already existing tile pixmap
        removeTileAt(scenePos);

        // add the pixmap to the scene
        if (!tile)
        {
            continue;
        }

        auto tilePixmap = (*state->getTileset())[tile.id];

        // TODO: change the color of the pixmap, based on palette index!

        auto item = addPixmap(tilePixmap);
        item->setPos(scenePos);

        // store the tile ID in pixmap item's data
        item->setData(DataKey::TILE_INDEX, QVariant::fromValue(tile.id));
    }
}

QPoint Scene::mapFromLevel(const QPoint &p) const
{
    return QPoint(p.x() * 8, -30 * 8 + p.y() * 8);
}
