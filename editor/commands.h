#ifndef COMMANDS_H
#define COMMANDS_H

#include "level.h"

#include <QUndoCommand>

// Set a tile at given coordinate.
QUndoCommand* newSetTileCommand(Coord coord, Tile tile);

#endif // COMMANDS_H
