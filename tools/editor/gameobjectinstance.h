#ifndef GAMEOBJECTINSTANCE_H
#define GAMEOBJECTINSTANCE_H

#include <QObject>
#include <QString>
#include <QtQml/qqml.h>

#include "gameobject.h"

class GameObjectInstance : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(GameObject* prototype READ getPrototype WRITE setPrototype NOTIFY prototypeChanged)
    Q_PROPERTY(QPoint position READ getPosition WRITE setPosition NOTIFY positionChanged)

    GameObject *m_prototype;
    QPoint m_position;

public:
    explicit GameObjectInstance(QObject *parent = nullptr, GameObject *prototype = nullptr);

    QPoint getPosition() const;
    void setPosition(const QPoint &position);
    GameObject* getPrototype() const;
    void setPrototype(GameObject *prototype);

signals:
    void positionChanged(QPoint position);
    void prototypeChanged(GameObject *prototype);
};

#endif // GAMEOBJECTINSTANCE_H
