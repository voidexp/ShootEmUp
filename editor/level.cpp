#include "level.h"

Level::Level(QObject *parent)
    : QObject{parent}
{

}

void Level::setTileAt(Coord coord, const Tile &tile)
{
    if (tile)
    {
        tiles_[coord] = tile;
    }
    else
    {
        tiles_.remove(coord);
    }

    emit tilesChanged({{coord, tile}});
}

Tile Level::tileAt(Coord coord) const
{
    return tiles_[coord];
}
/*
TileData Level::tiles() const
{
    TileData data;

    auto i = tiles_.constBegin();
    while (i != tiles_.constEnd())
    {
        auto coord = i.key();
        auto tile = i.value();
        data.append({coord, tile});
        ++i;
    }

    return data;
}

void Level::setTiles(const TileData &tileData)
{
    TileData changedTiles = tiles();
    changedTiles.append(tileData);
    tiles_.clear();

    for (auto const &i : tileData)
    {
        auto [coord, tile] = i;
        tiles_[coord] = tile;
    }

    emit tilesChanged(changedTiles);
}
*/
