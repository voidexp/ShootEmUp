#ifndef SCENE_H
#define SCENE_H

#include "level.h"

#include <QGraphicsScene>

class Scene : public QGraphicsScene
{
public:
    explicit Scene(QObject *parent = nullptr);

    void addTileAt(const QPoint &loc, int id);
    void removeTileAt(const QPoint &loc);
    int getTileAt(const QPoint &loc) const;

    QPoint mapFromLevel(const QPoint &point) const;

protected slots:
    void updateTiles(const TileData &tiles);
};

#endif // SCENE_H
