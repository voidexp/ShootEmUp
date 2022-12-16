#include "state.h"

#include <QImageReader>
#include <QPixmap>
#include <QFileDialog>
#include <QMessageBox>
#include <QSettings>

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
    , tileset_(new Tileset{})
    , level_(new Level{})
{
}

void State::setTileset(Tileset *tileset)
{
    tileset_ = std::unique_ptr<Tileset>(tileset);
    emit tilesetChanged(tileset);
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

void State::loadTilesetFromFile()
{
    if (true) // FIXME: check whether there are already tiles on the scene
    {
        QMessageBox box{
                    QMessageBox::Icon::Warning,
                    "Erase background?",
                    "There are tiles associated with this tileset.\nLoading a new one will erase them.\nProceed?",
                    QMessageBox::Ok | QMessageBox::Cancel};

        auto result = box.exec();

        // settings are stored in Registry (on Windows), save there the last
        // accessed tileset directory for some additional mental sanity
        QSettings settings;

        if (result == QMessageBox::Ok)
        {
            QFileDialog dialog{
                nullptr,
                "Select a CHR file...",
                settings.value("editor/lastTilesetDir").toString(),
                "*.chr"
            };

            if (dialog.exec())
            {
                settings.setValue("editor/lastTilesetDir", dialog.directory().path());

                auto files = dialog.selectedFiles();
                auto filename = files[0];
                qDebug() << "Loading tileset" << filename;
                auto tileset = Tileset::loadFromFile(filename);
                Q_ASSERT(tileset->valid());
                setTileset(tileset);
            }
        }
    }
}

void State::pushCommand(QUndoCommand* cmd)
{
    undoStack_.push(cmd);
}
