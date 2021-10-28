QT += quick qml

CONFIG += c++11 qmltypes file_copies

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

QML_IMPORT_NAME = Editor
QML_IMPORT_MAJOR_VERSION = 1

qmltypes.files = $$files($$OUT_PWD/*.qmltypes)
qmltypes.path = $$PWD/Editor

COPIES += qmltypes

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH += $$PWD

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    gameobject.h \
    gameobjectinstance.h \
    leveldata.h

SOURCES += \
        gameobject.cpp \
        gameobjectinstance.cpp \
        leveldata.cpp \
        main.cpp

RESOURCES += qml.qrc

INCLUDEPATH += $$PWD/include

debug {
    LIBS += $$PWD/lib/yaml-cppd.lib
} else {
    LIBS += $$PWD/lib/yaml-cpp.lib
}
