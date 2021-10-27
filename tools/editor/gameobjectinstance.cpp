#include "gameobjectinstance.h"

#include <QVariant>

GameObjectInstance::GameObjectInstance(QObject *parent, GameObject *prototype) :
    QObject(parent),
    m_prototype(prototype)
{
}

QPoint GameObjectInstance::getPosition() const
{
    return m_position;
}

void GameObjectInstance::setPosition(const QPoint &position)
{
    m_position = position;
    emit positionChanged(m_position);
}

GameObject* GameObjectInstance::getPrototype() const
{
    return m_prototype;
}

void GameObjectInstance::setPrototype(GameObject *prototype)
{
    m_prototype = prototype;
    emit prototypeChanged(m_prototype);
}
