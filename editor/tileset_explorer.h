#ifndef TILESETEXPLORER_H
#define TILESETEXPLORER_H

#include <QWidget>
#include <QGraphicsScene>
#include <QGraphicsView>
#include <memory>
#include "ui_tileset_explorer.h"


class TilesetExplorer : public QWidget
{
    Q_OBJECT

public:
    explicit TilesetExplorer(QWidget *parent = nullptr);

public slots:
    void loadTilesetFile(const QString &file);

private:
    std::unique_ptr<Ui::TilesetExplorer> ui;
    QGraphicsScene scene;

};

#endif // TILEMAPEXPLORER_H
