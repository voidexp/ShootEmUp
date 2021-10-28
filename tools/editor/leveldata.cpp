#include <algorithm>
#include <iterator>

#include <QVariantList>
#include <QFile>
#include <QDebug>

#include <yaml-cpp/yaml.h>

#include "leveldata.h"

extern QList<GameObject*> g_gameObjects;

LevelData::LevelData(QObject *parent):
    QObject(parent)
{

}

QVariant LevelData::getGameObjects()
{
    return QVariant::fromValue(m_objects);
}

void LevelData::setGameObjects(const QVariant &gameObjectsList)
{
    m_objects = QList<GameObjectInstance*>();
    auto list = gameObjectsList.value<QVariantList>();
    for (auto &obj : list)
    {
        m_objects.append(obj.value<GameObjectInstance*>());
    }

    emit gameObjectsChanged(QVariant::fromValue(m_objects));
}

void LevelData::save(const QUrl &filename)
{
    Q_ASSERT(filename.isLocalFile());

    YAML::Emitter yaml;
    yaml << YAML::Comment("\nShoot'em Up level file\n");
    yaml << YAML::BeginMap;

    yaml << YAML::Key << "gameobjects";
    yaml << YAML::Value << YAML::BeginSeq;
    for (auto obj : m_objects)
    {
        auto pos = obj->getPosition();
        yaml << YAML::BeginMap;
        yaml << YAML::Key << "name" << YAML::Value << obj->getPrototype()->getName().toStdString();
        yaml << YAML::Key << "position" << YAML::Value << YAML::Flow << YAML::BeginSeq << pos.x() << pos.y() << YAML::EndSeq;
        yaml << YAML::EndMap;
    }
    yaml << YAML::EndSeq;
    yaml << YAML::EndMap;

    QFile file(filename.toLocalFile());
    file.open(QFile::WriteOnly);
    file.write(yaml.c_str());
    file.close();
}

void LevelData::load(const QUrl &filename)
{
    Q_ASSERT(filename.isLocalFile());

    // read the file
    QFile file(filename.toLocalFile());
    file.open(QFile::ReadOnly);
    auto content = file.readAll().toStdString();
    file.close();

    // parse the YAML structure
    YAML::Node levelNode = YAML::Load(content);
    Q_ASSERT(levelNode.IsMap());

    // create a new list for game object instances and fill it with new instances, created as we go
    auto objects = QList<GameObjectInstance*>();
    auto gameObjectsNode = levelNode["gameobjects"];
    Q_ASSERT(gameObjectsNode.IsDefined());
    Q_ASSERT(gameObjectsNode.IsSequence());
    for (auto goNode : gameObjectsNode)
    {
        // each game object instance entry is a map
        Q_ASSERT(goNode.IsMap());

        // read the game object name
        auto nameNode = goNode["name"];
        Q_ASSERT(nameNode.IsDefined() && nameNode.IsScalar());
        auto name = QString::fromStdString(nameNode.as<std::string>());

        // read the position
        auto positionNode = goNode["position"];
        Q_ASSERT(positionNode.IsDefined() && positionNode.IsSequence() && positionNode.size() == 2);
        int x = positionNode[0].as<int>();
        int y = positionNode[1].as<int>();

        // attempt to find the reference game object by name in the global registry
        auto refGameObject = std::find_if(
            std::begin(g_gameObjects),
            std::end(g_gameObjects),
            [&](auto obj){return obj->getName() == name;}
        );
        if (refGameObject == std::end(g_gameObjects))
        {
            qWarning() << "Skipped unknown game object type:" << name << "";
            continue;
        }

        // create the instance and append it to the list
        auto gameObjectInstance = new GameObjectInstance(this, *refGameObject);
        gameObjectInstance->setPosition(QPoint(x, y));
        objects.append(gameObjectInstance);
    }

    // update
    m_objects = objects;
    emit gameObjectsChanged(QVariant::fromValue(m_objects));
}
