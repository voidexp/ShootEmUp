#include "gameobjectinstance.h"

#include <QVariant>

GameObjectInstance::GameObjectInstance(std::shared_ptr<GameObject> prototype, QObject *parent) :
    QObject(parent),
    m_prototype(prototype)
{

}

QString GameObjectInstance::getName() const
{
    return m_prototype->property("name").toString();
}

QRect GameObjectInstance::getRect() const
{
    return m_prototype->property("rect").toRect();
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
