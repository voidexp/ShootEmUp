#include "chrplugin.h"

#include <QImageIOHandler>

// Check out https://www.nesdev.org/wiki/PPU_pattern_tables

class CHRIOHandler : public QImageIOHandler
{
public:
    bool canRead() const override
    {
        auto pos = device()->pos();
        return pos >= 0 && pos <= 4096;
    }

    bool read(QImage *image) override
    {
        // read the next pattern from the device
        auto chrData = device()->read(16);
        if (chrData.length() != 16)
        {
            return false;
        }

        // decode the bitplanes
        auto pixelData = new uchar[8 * 8 * 8]{};
        for (int y = 0; y < 8; y++)
        {
            for (int x = 0; x < 8; x++)
            {
                int bit0 = chrData[y] >> (7 - x) & 1;
                int bit1 = chrData[y + 8] >> (7 - x) & 1;
                pixelData[y * 8 + x] = (bit1 << 1) | bit0;
            }
        }

        // create the indexed image and set a palette
        auto img = QImage(pixelData, 8, 8, QImage::Format::Format_Indexed8, cleanupFunc, pixelData);
        img.setColorCount(4);
        img.setColorTable(QList<QRgb>{
            Qt::transparent,
            QRgb(0x6844fcff),
            QRgb(0x9878f8ff),
            QRgb(0xd8b8f8ff),
        });

        *image = img;

        return true;
    }

private:
    static void cleanupFunc(void *ptr)
    {
        auto data = static_cast<uchar*>(ptr);
        delete[] data;
    }
};

CHRImageIOPlugin::CHRImageIOPlugin(QObject *parent)
    : QImageIOPlugin(parent)
{
    qDebug() << "CHR image plugin loaded";
}

QImageIOPlugin::Capabilities CHRImageIOPlugin::capabilities(QIODevice *device, const QByteArray &format) const
{
    if (format == "chr")
    {
        return CanRead;
    }
    return Capabilities::fromInt(0);
}

QImageIOHandler *CHRImageIOPlugin::create(QIODevice *device, const QByteArray &format) const
{
    auto handler = new CHRIOHandler();
    handler->setDevice(device);
    handler->setFormat(format);
    return handler;
}
