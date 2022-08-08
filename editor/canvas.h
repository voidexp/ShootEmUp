#ifndef CANVAS_H
#define CANVAS_H

#include <QWidget>

class Canvas : public QWidget
{
    Q_OBJECT
public:
    explicit Canvas(QWidget *parent = nullptr);

    virtual void paintEvent(QPaintEvent *) override;

signals:

};

#endif // CANVAS_H
