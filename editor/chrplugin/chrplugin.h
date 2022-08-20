#ifndef CHRPLUGIN_H
#define CHRPLUGIN_H

#include <QImageIOPlugin>

class CHRImageIOPlugin : public QImageIOPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QImageIOHandlerFactoryInterface_iid FILE "chrplugin.json")

public:
    explicit CHRImageIOPlugin(QObject *parent = nullptr);

private:
    QImageIOPlugin::Capabilities capabilities(QIODevice *device, const QByteArray &format) const override;
    QImageIOHandler *create(QIODevice *device, const QByteArray &format) const override;
};

#endif // CHRPLUGIN_H
