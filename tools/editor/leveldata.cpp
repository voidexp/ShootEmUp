#include <algorithm>
#include <iterator>

#include <QVariantList>
#include <QFile>
#include <QDebug>

#include <yaml-cpp/yaml.h>

#include "leveldata.h"

extern QList<GameObject*> g_gameObjects;

Stage::Stage(QObject *parent):
    QObject(parent)
{

}

Stage::~Stage()
{
}

QVariant Stage::getGameObjects()
{
    return QVariant::fromValue(m_objects);
}

void Stage::setGameObjects(const QVariant &gameObjectsList)
{
    m_objects = QList<GameObjectInstance*>();
    auto list = gameObjectsList.value<QVariantList>();
    for (auto &obj : list)
    {
        m_objects.append(obj.value<GameObjectInstance*>());
    }

    emit gameObjectsChanged(QVariant::fromValue(m_objects));
}


LevelData::LevelData(QObject *parent):
    QAbstractListModel(parent)
{
    clear();
}

void LevelData::save(const QUrl &filename)
{
    Q_ASSERT(filename.isLocalFile());

    YAML::Emitter yaml;
    yaml << YAML::Comment("\nShoot'em Up level file\n");
    yaml << YAML::BeginMap;

    // serialize the sequence of game stages
    yaml << YAML::Key << "stages";
    yaml << YAML::Value << YAML::BeginSeq;
    for (auto stage : m_stages)
    {
        yaml << YAML::BeginMap;

        yaml << YAML::Key << "gameobjects";
        yaml << YAML::Value << YAML::BeginSeq;
        for (auto &objVariant : stage->getGameObjects().value<QVariantList>())
        {
            auto obj = objVariant.value<GameObjectInstance*>();
            auto pos = obj->getPosition();
            yaml << YAML::BeginMap;
            yaml << YAML::Key << "name" << YAML::Value << obj->getPrototype()->getName().toStdString();
            yaml << YAML::Key << "position" << YAML::Value << YAML::Flow << YAML::BeginSeq << pos.x() << pos.y() << YAML::EndSeq;
            yaml << YAML::EndMap;
        }
        yaml << YAML::EndSeq;
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

    auto stagesNode = levelNode["stages"];
    Q_ASSERT(stagesNode.IsDefined());
    Q_ASSERT(stagesNode.IsSequence());
    Q_ASSERT_X(stagesNode.size() >= 1, "stages loading", "there must be at least one stage defined");

    beginResetModel();
    m_stages.clear();

    for (auto stageNode : stagesNode)
    {
        Q_ASSERT(stageNode.IsMap());

        // create a new list for game object instances and fill it with new instances, created as we go
        auto objects = QList<GameObjectInstance*>();
        auto gameObjectsNode = stageNode["gameobjects"];
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

        // create the stage
        auto stage = new Stage(this);
        stage->setGameObjects(QVariant::fromValue(objects));
        m_stages.append(stage);
    }

    endResetModel();
    emit sizeChanged(m_stages.size());
}

void LevelData::clear()
{
    beginResetModel();

    for (auto stage : m_stages)
    {
        delete stage;
    }
    m_stages.clear();

    // there must be always be at least one stage
    m_stages.append(new Stage(this));

    endResetModel();
    emit sizeChanged(m_stages.size());
}

QVariant LevelData::get(int index)
{
    if (index >= 0 && index < m_stages.size())
    {
        return QVariant::fromValue(m_stages[index]);
    }

    return {};
}

void LevelData::addNewStage()
{
    auto lastRow = m_stages.size();
    beginInsertRows(QModelIndex(), lastRow, lastRow);
    m_stages.append(new Stage(this));
    endInsertRows();
    emit sizeChanged(m_stages.size());
}

void LevelData::removeStage(int index)
{
    if (index >= 0 && index < m_stages.size())
    {
        beginRemoveRows(QModelIndex(), index, index);
        m_stages.removeAt(index);
        endRemoveRows();

        emit sizeChanged(m_stages.size());
    }
}

int LevelData::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_stages.size();
}

QVariant LevelData::data(const QModelIndex &index, int role) const
{
    if (role == Qt::DisplayRole && index.row() <= m_stages.size())
    {
        return QVariant::fromValue(m_stages[index.row()]);
    }
    return QVariant();
}

int LevelData::getSize() const
{
    return m_stages.size();
}
