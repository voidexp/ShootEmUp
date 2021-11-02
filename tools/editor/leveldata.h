#ifndef LEVELDATA_H
#define LEVELDATA_H

#include <QObject>
#include <QList>
#include <QAbstractListModel>
#include <qqml.h>

#include "gameobjectinstance.h"

class Stage : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariant gameObjects READ getGameObjects WRITE setGameObjects NOTIFY gameObjectsChanged)

    QList<GameObjectInstance*> m_objects;

public:
    Stage(QObject *parent = nullptr);
    ~Stage();

    QVariant getGameObjects();
    void setGameObjects(const QVariant &gameObjectsList);

signals:
    void gameObjectsChanged(QVariant gameObjects);
};


class LevelData : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int size READ getSize NOTIFY sizeChanged)

    QList<Stage*> m_stages;

public:
    LevelData(QObject *parent = nullptr);

    Q_INVOKABLE void save(const QUrl &filename);
    Q_INVOKABLE void load(const QUrl &filename);
    Q_INVOKABLE void clear();

    Q_INVOKABLE QVariant get(int index);

    Q_INVOKABLE void addNewStage();
    Q_INVOKABLE void removeStage(int index);

    int getSize() const;

    virtual int rowCount(const QModelIndex &parent = QModelIndex()) const;
    virtual QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

signals:
    void sizeChanged(int size);
};

#endif // LEVELDATA_H
