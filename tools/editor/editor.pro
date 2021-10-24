QT += quick

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        gameobject.cpp \
        main.cpp

RESOURCES += qml.qrc

INCLUDEPATH += $$PWD/include

debug {
    LIBS += $$PWD/lib/yaml-cppd.lib
} else {
    LIBS += $$PWD/lib/yaml-cpp.lib
}

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH = qml

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DISTFILES += \
    qml/Controls/Button.qml \
    qml/MapCanvas.qml \
    qml/ObjectsPanel.qml \
    qml/Style.qml \
    qml/main.qml \
    qml/qmldir

HEADERS += \
    gameobject.h
