#ifndef GAMEOBJECT_H
#define GAMEOBJECT_H

#include <QObject>
#include <QString>
#include <QRect>
#include <qqml.h>

class GameObject : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    QString m_name;
    QRect m_rect;

    Q_PROPERTY(QString name READ getName CONSTANT)
    Q_PROPERTY(QRect rect MEMBER m_rect CONSTANT)

public:
    explicit GameObject(QObject *parent = nullptr);
    explicit GameObject(const QString &name, const QRect& rect);

    QString getName() const;

signals:

};

#endif // GAMEOBJECT_H
