#include <QPainter>

#include "canvas.h"

Canvas::Canvas(QWidget *parent)
    : QWidget{parent}
{

}

void Canvas::paintEvent(QPaintEvent *evt)
{
    QPainter p(this);

    p.setPen(Qt::blue);
    p.setFont(QFont("Arial", 30));
    p.drawText(rect(), Qt::AlignCenter, "SHMUP editor!");
}
