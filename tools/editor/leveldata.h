#ifndef LEVELDATA_H
#define LEVELDATA_H

#include <QObject>
#include <QList>
#include <qqml.h>

#include "gameobjectinstance.h"

class LevelData : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVariant gameObjects READ getGameObjects WRITE setGameObjects NOTIFY gameObjectsChanged)

    QList<GameObjectInstance*> m_objects;

public:
    LevelData(QObject *parent = nullptr);

    QVariant getGameObjects();
    void setGameObjects(const QVariant &gameObjectsList);

signals:
    void gameObjectsChanged(QVariant gameObjects);

};

#endif // LEVELDATA_H
