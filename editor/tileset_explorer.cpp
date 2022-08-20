#include "tileset_explorer.h"

#include <QImageReader>
#include <QGraphicsScene>
#include <QGraphicsPixmapItem>

TilesetExplorer::TilesetExplorer(QWidget *parent)
    : QWidget{parent}
    , ui(new Ui::TilesetExplorer)
{
    ui->setupUi(this);
    ui->graphicsView->setScene(&scene);
    ui->graphicsView->setBackgroundBrush(QBrush(Qt::black));
    ui->graphicsView->scale(2.0, 2.0);

    auto reader = QImageReader("../assets/tilesets/ships.chr");
    for (int row = 0; row < 16; row++)
    {
        for (int col = 0; col < 16; col++)
        {
            auto img = reader.read();
            auto pixmap = QPixmap::fromImage(img);
            auto item = scene.addPixmap(pixmap);
            item->setPos(col * img.width(), row * img.height());
        }
    }
}
