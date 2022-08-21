#ifndef TILESET_VIEW_H
#define TILESET_VIEW_H

#include <QGraphicsView>

class TilesetView : public QGraphicsView
{
    Q_OBJECT

public:
    explicit TilesetView(QWidget *parent = nullptr);

protected:
    void drawForeground(QPainter *painter, const QRectF &rect) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;

signals:
    void tileSelected(int tileID);

private:
    QPoint cursorPos;
};

#endif // TILESET_VIEW_H
