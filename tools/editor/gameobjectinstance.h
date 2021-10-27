#ifndef GAMEOBJECTINSTANCE_H
#define GAMEOBJECTINSTANCE_H

#include <memory>

#include <QObject>
#include <QString>
#include <QtQml/qqml.h>

#include "gameobject.h"

class GameObjectInstance : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString name READ getName CONSTANT)
    Q_PROPERTY(QRect rect READ getRect CONSTANT)
    Q_PROPERTY(QPoint position READ getPosition WRITE setPosition NOTIFY positionChanged)

    std::shared_ptr<GameObject> m_prototype;
    QPoint m_position;

public:
    explicit GameObjectInstance(std::shared_ptr<GameObject> prototype, QObject *parent = nullptr);

    QString getName() const;
    QRect getRect() const;
    QPoint getPosition() const;
    void setPosition(const QPoint &position);

signals:
    void positionChanged(QPoint position);
};

#endif // GAMEOBJECTINSTANCE_H
