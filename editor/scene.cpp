#include "scene.h"

Scene::Scene(QObject *parent)
    : QGraphicsScene{parent}
{
    // initial size -> one screen; screens grow to negative Y (up)
    setSceneRect(0, 0, 32*8, -30*8);
}
