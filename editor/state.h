#ifndef STATE_H
#define STATE_H

#include <QObject>
#include <QList>
#include <memory>

enum DataKey
{
    TILE_INDEX,
};

/*
 * Tileset
 */
class Tileset : public QObject
{
    Q_OBJECT

public:
    explicit Tileset();
    QPixmap operator[](int id) const;

    bool valid() const { return tiles.size() == 256; }

    static Tileset* loadFromFile(const QString &filename);

private:
    QList<QPixmap> tiles;
};

Q_DECLARE_METATYPE(Tileset)

/*
 * Current brush state.
 */
class Brush : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int tile READ getTile WRITE setTile NOTIFY tileChanged STORED true)
    Q_PROPERTY(int size READ getTile WRITE setTile NOTIFY sizeChanged STORED true)

public:
    explicit Brush(QObject *parent = nullptr): QObject(parent) {}

    int getSize() const { return size_; }
    void setSize(int size) { size_ = size; emit sizeChanged(size); }

    int getTile() const { return tile_; }
    void setTile(int tile) { tile_ = tile; emit tileChanged(tile); }

signals:
    void tileChanged(int tile);
    void sizeChanged(int size);

private:
    int tile_ = 0;
    int size_ = 1;
};

Q_DECLARE_METATYPE(Brush)


/*
 * Editor state: brushes, palettes, tilesets, etc.
 */
class State : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Brush* brush READ getBrush CONSTANT)
    Q_PROPERTY(Tool activeTool READ getActiveTool WRITE setActiveTool NOTIFY activeToolChanged)
    Q_PROPERTY(Tileset* tileset READ getTileset WRITE setTileset NOTIFY tilesetChanged)

public:
    enum class Tool {
        NONE,
        BRUSH,
    };

    Q_ENUM(Tool)

    static State* get();

    Brush* getBrush() { return brush_; }

    Tool getActiveTool() const { return activeTool_; }
    void setActiveTool(Tool tool) { activeTool_ = tool; emit activeToolChanged(tool); }

    Tileset *getTileset() const { return tileset_.get(); }

    void setTileset(Tileset *tileset)
    {
        tileset_ = std::unique_ptr<Tileset>(tileset);
        emit tilesetChanged(tileset);
    }

signals:
    void activeToolChanged(State::Tool tool);
    void tilesetChanged(Tileset *tileset);

private:
    explicit State(QObject *parent = nullptr);

    Brush *brush_ = nullptr;
    Tool activeTool_ = Tool::NONE;
    std::unique_ptr<Tileset> tileset_;
};

#endif // STATE_H
