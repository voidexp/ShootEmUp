pragma Singleton
import QtQuick 2.0

QtObject {
    readonly property color bg: "#0b1a28"
    readonly property color fg: "#164550"
    readonly property color lo: "#348780"
    readonly property color hi: "#c2f0ea"

    readonly property FontLoader iconFont: FontLoader {
        source: "qrc:/fontawesome.otf"
    }

    readonly property int iconSize: 16

    readonly property QtObject icons: QtObject {
        readonly property string file: "\uf15b"
        readonly property string folderOpen: "\uf07c"
        readonly property string save: "\uf0c7"
        readonly property string add: "\uf0fe"
        readonly property string remove: "\uf146"
    }
}
