#ifndef TILESETEXPLORER_H
#define TILESETEXPLORER_H

#include <QWidget>
#include <QGraphicsScene>
#include <QGraphicsView>
#include <memory>
#include "ui_tileset_explorer.h"

class Tileset;

class TilesetExplorer : public QWidget
{
    Q_OBJECT

public:
    explicit TilesetExplorer(QWidget *parent = nullptr);

protected slots:
    void updateTileset(Tileset *tileset);

private:
    std::unique_ptr<Ui::TilesetExplorer> ui;
    QGraphicsScene scene;

};

#endif // TILEMAPEXPLORER_H
