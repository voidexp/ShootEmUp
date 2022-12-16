#include "tileset_explorer.h"
#include "tileset_view.h"
#include "state.h"

#include <QImageReader>
#include <QGraphicsPixmapItem>


TilesetExplorer::TilesetExplorer(QWidget *parent)
    : QWidget{parent}
    , ui(new Ui::TilesetExplorer)
{
    ui->setupUi(this);
    ui->graphicsView->setScene(&scene);

    auto state = State::get();

    // When clicking on load button, initiate a loading of the tileset from file
    connect(ui->loadButton, &QToolButton::clicked, state, &State::loadTilesetFromFile);

    // On tile selection, set the current brush tile ID
    connect(ui->graphicsView, &TilesetView::tileSelected, this, [=](int tileID){
        qDebug() << "Using tile" << tileID;
        State::get()->getBrush()->setTile(tileID);
    });

    // On tileset change, update the scene
    connect(state, &State::tilesetChanged, this, &TilesetExplorer::updateTileset);
}

void TilesetExplorer::updateTileset(Tileset *tileset)
{
    scene.clear();

    for (int row = 0; row < 16; row++)
    {
        for (int col = 0; col < 16; col++)
        {
            auto id = row * 16 + col;
            auto pixmap = (*tileset)[id];
            auto item = scene.addPixmap(pixmap);
            item->setPos(col * pixmap.width(), row * pixmap.height());
            item->setData(DataKey::TILE_INDEX, QVariant(id));
        }
    }
}
