#ifndef GAMEOBJECT_H
#define GAMEOBJECT_H

#include <QObject>
#include <QString>
#include <QRect>

class GameObject : public QObject
{
    Q_OBJECT

    QString m_name;
    QRect m_rect;

    Q_PROPERTY(QString name MEMBER m_name CONSTANT)
    Q_PROPERTY(QRect rect MEMBER m_rect CONSTANT)

public:
    explicit GameObject(QObject *parent = nullptr);
    explicit GameObject(const QString &name, const QRect& rect);

signals:

};

#endif // GAMEOBJECT_H
