/**
 * Core game level data structures.
 *
 * These data classes define what a game level is and what entities
 * populate it, from background tiles to those nice scripted enemy spaceship
 * instances. No code and data that implements UI, file I/O, scene rendering,
 * bucket fill tools, and etc goes here. The public methods of these classes
 * provide only the low-level functionality, higher-level operations, such as
 * placing enemies in a star pattern, copy-pasting, bucket filling the entire
 * screen with stars and similar should be implemented separately as Commands
 * (see commands.h), extending these classes only if necessary to support those
 * operations.
 */

#ifndef LEVEL_H
#define LEVEL_H

#include <QObject>
#include <QMap>
#include <QHash>
#include <QSharedPointer>
#include <QList>
#include <tuple>

/**
 * @brief A tile coordinate.
 */
struct Coord
{
    int col;
    int row;

    bool operator<(const Coord &other) const { return col < other.col && row < other.row; }
};


inline bool operator==(const Coord &c1, const Coord &c2)
{
    return c1.col == c2.col && c1.row == c2.row;
}

inline size_t qHash(const Coord &key, size_t seed)
{
    return qHashMulti(seed, key.col, key.row);
}

/**
 * @brief A background tile.
 */
struct Tile
{
    int id;
    int palette;

    Tile(): id(-1), palette(0) {};
    Tile(int tileId, int palette): id(tileId), palette(palette) {};

    bool isValid() const { return id != -1; }
    operator bool() const { return isValid(); };
};


using TileData = QList<std::tuple<Coord, Tile>>;

/**
 * @brief The mighty game level god object.
 *
 * Container for everything that could be placed in a level: enemies, spawn
 * positions, backgrounds, triggers, etc.
 *
 * This is a REACTIVE data structure. It uses the QObject signals to notify
 * subscribers about state changes.
 */
class Level : public QObject
{
    Q_OBJECT
public:
    explicit Level(QObject *parent = nullptr);

    Tile tileAt(Coord coord) const;
    void setTileAt(Coord coord, const Tile &tile);
    /*
    TileData tiles() const;
    void setTiles(const TileData &tileData);
    */

signals:
    void tilesChanged(const TileData &tiles);

private:
    QHash<Coord, Tile> tiles_;
};

#endif // LEVEL_H
