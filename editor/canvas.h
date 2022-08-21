#ifndef CANVAS_H
#define CANVAS_H

#include <QGraphicsView>

class Canvas : public QGraphicsView
{
public:
    explicit Canvas(QWidget *parent = nullptr);

protected:
    void drawForeground(QPainter *painter, const QRectF &rect) override;
    void drawBackground(QPainter *painter, const QRectF &rect) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;

private:
    QBrush bgBrush;
    QPoint cursorPos;

    QPointF sceneToLevel(const QPointF &point);
    QPointF levelToScene(const QPointF &point);
};

#endif // CANVAS_H
