#include "state.h"

#include <QImageReader>
#include <QPixmap>

Tileset::Tileset()
    : QObject(nullptr)
{

}

QPixmap Tileset::operator[](int id) const
{
    return tiles[id];
}

Tileset* Tileset::loadFromFile(const QString &filename)
{
    auto tileset = new Tileset{};
    auto reader = QImageReader(filename);
    for (int row = 0; row < 16; row++)
    {
        for (int col = 0; col < 16; col++)
        {
            auto img = reader.read();
            auto pixmap = QPixmap::fromImage(img);
            tileset->tiles.append(pixmap);
        }
    }

    return tileset;
}

State::State(QObject *parent)
    : QObject{parent}
    , brush_(new Brush{this})
    , tileset_(new Tileset())
{

}

State* State::get()
{
    static State *_state = nullptr;

    if (!_state)
    {
        _state = new State{nullptr};
    }

    return _state;
}
