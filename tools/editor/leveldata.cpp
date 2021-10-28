#include <QVariantList>

#include "leveldata.h"

LevelData::LevelData(QObject *parent):
    QObject(parent)
{

}

QVariant LevelData::getGameObjects()
{
    return QVariant::fromValue(m_objects);
}

void LevelData::setGameObjects(const QVariant &gameObjectsList)
{
    m_objects = QList<GameObjectInstance*>();
    auto list = gameObjectsList.value<QVariantList>();
    for (auto &obj : list) {
        m_objects.append(obj.value<GameObjectInstance*>());
    }

    emit gameObjectsChanged(QVariant::fromValue(m_objects));
}
