#include "commands.h"
#include "state.h"

QUndoCommand* newSetTileCommand(Coord coord, Tile tile)
{
    class SetTileCommand : public QUndoCommand
    {
        Tile tile, prevTile;
        Coord coord;

    public:
        SetTileCommand(Coord coord, Tile tile)
            : QUndoCommand(QString::asprintf("set tile at %d,%d", coord.row, coord.col))
            , tile(tile)
            , coord(coord)
        {}

        virtual void redo()
        {
            auto level = State::get()->level();
            prevTile = level->tileAt(coord);
            level->setTileAt(coord, tile);
        };

        virtual void undo()
        {
            auto level = State::get()->level();
            level->setTileAt(coord, prevTile);
        }
    };

    return new SetTileCommand{coord, tile};
}

