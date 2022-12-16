#include "mainwindow.h"

#include <QApplication>
#include <QResource>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    a.setOrganizationDomain("voidexp");
    a.setOrganizationDomain("voidexp.me");
    a.setApplicationName("SHMUP editor");

    QResource::registerResource("resources.rcc");

    MainWindow w;
    w.show();

    return a.exec();
}
