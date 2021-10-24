#include "gameobject.h"

GameObject::GameObject(QObject *parent) : QObject(parent)
{

}

GameObject::GameObject(const QString &name, const QRect &rect) :
    QObject(nullptr),
    m_name(name),
    m_rect(rect)
{

}
