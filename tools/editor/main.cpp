#include <QObject>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QVariant>
#include <QMap>
#include <QFileInfo>
#include <QDebug>
#include <QImage>
#include <QQuickImageProvider >

#include <yaml-cpp/yaml.h>

#include "gameobject.h"

const QString objectsSpecFile = "../../assets/objects.yaml";


class GameObjectImageProvider : public QQuickImageProvider
{
    QMap<QString, QImage> m_images;

public:
    GameObjectImageProvider(): QQuickImageProvider(QQmlImageProviderBase::Image) {}

    void addImage(const QString &id, QImage img)
    {
        if (!m_images.contains(id))
        {
            m_images[id] = img;
        }
    }

    virtual QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize)
    {
        Q_UNUSED(size)
        Q_UNUSED(requestedSize)
        return m_images[id];
    }
};


static GameObject* readObjectEntry(const YAML::Node& node, const QString &resPrefix, QMap<QString, QImage> &resMap, GameObjectImageProvider *provider)
{
    // read the `name` value
    assert(node["name"].IsDefined());
    assert(node["name"].IsScalar());
    const auto& name = QString::fromStdString(node["name"].as<std::string>());

    // read the `rect` value
    assert(node["rect"].IsDefined());
    assert(node["rect"].IsSequence());
    assert(node["rect"].size() == 4);
    const auto &rect = node["rect"];
    int x = rect[0].as<int>();
    int y = rect[1].as<int>();
    int w = rect[2].as<int>();
    int h = rect[3].as<int>();

    // read the `sheet` value
    assert(node["sheet"].IsDefined());
    assert(node["sheet"].IsScalar());
    const auto &path = resPrefix + "/" + QString::fromStdString(node["sheet"].as<std::string>());
    if (!resMap.contains(path)) {
        assert(QFileInfo::exists(path));

        qDebug() << "loading" << path;

        // load the image, create an alpha channel from the black color mask and store it in the resMap
        auto img = QImage(path);
        auto mask = img.createMaskFromColor(qRgb(0, 0, 0), Qt::MaskOutColor);
        img = img.convertToFormat(QImage::Format_RGBA8888);
        img.setAlphaChannel(mask);

        resMap[path] = img;
    }

    // create a subimage frame for the given object and add it to the QML image provider
    provider->addImage(name, resMap[path].copy(x, y, w, h));

    return new GameObject(
        name,
        QRect{x, y, w, h}
    );
}


int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);

    QMap<QString, QImage> images;
    GameObjectImageProvider *provider = new GameObjectImageProvider;

    // Resource directory, inferred from the objects spec file path
    const auto &resPath = QFileInfo(objectsSpecFile).absolutePath();
    assert(QFileInfo::exists(resPath));

    // Read objects specs and populate the model for QML
    QList<QObject *> objectsSpecData;
    YAML::Node spec = YAML::LoadFile(objectsSpecFile.toStdString());
    for (int i = 0; i < spec.size(); i++)
    {
        const auto& objSpec = spec[i];
        objectsSpecData.append(readObjectEntry(objSpec, resPath, images, provider));
    }

    QQmlApplicationEngine engine;
    engine.addImageProvider("gameObjects", provider);
    engine.rootContext()->setContextProperty("gameObjects", QVariant::fromValue(objectsSpecData));
    engine.addImportPath("qrc:/");

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
