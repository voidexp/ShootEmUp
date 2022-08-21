#include "tileset_explorer.h"
#include "tileset_view.h"
#include "state.h"

#include <QImageReader>
#include <QGraphicsPixmapItem>
#include <QFileDialog>

TilesetExplorer::TilesetExplorer(QWidget *parent)
    : QWidget{parent}
    , ui(new Ui::TilesetExplorer)
{
    ui->setupUi(this);
    ui->graphicsView->setScene(&scene);

    // When clicking on load button, open a file dialog for selecting .chr files
    connect(ui->loadButton, &QToolButton::clicked, this, [=](){
        auto dialog = new QFileDialog{this, "Select a CHR file...", "../assets", "*.chr"};

        dialog->connect(dialog, &QFileDialog::fileSelected, this, &TilesetExplorer::loadTilesetFile);
        dialog->show();
    });

    // On tile selection, set the current brush tile ID
    connect(ui->graphicsView, &TilesetView::tileSelected, this, [=](int tileID){
        qDebug() << "Using tile" << tileID;
        State::get()->getBrush()->setTile(tileID);
    });
}

void TilesetExplorer::loadTilesetFile(const QString &file)
{
    qDebug() << "Loading tileset" << file;
    auto tileset = Tileset::loadFromFile(file);
    auto state = State::get();
    state->setTileset(tileset);

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
