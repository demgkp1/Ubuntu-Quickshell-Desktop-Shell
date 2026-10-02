pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    FontLoader {
        id: materialSymbolsLoader
        source: Qt.resolvedUrl("../assets/fonts/MaterialSymbolsRounded.ttf")
    }

    FontLoader {
        id: googleSansLoader
        source: Qt.resolvedUrl("../assets/fonts/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }

    readonly property string materialSymbolsRounded: materialSymbolsLoader.name.length > 0 ? materialSymbolsLoader.name : "Material Symbols Rounded"
    readonly property string expressive: googleSansLoader.name.length > 0 ? googleSansLoader.name : "Ubuntu"
    readonly property string ui: "Ubuntu"
    readonly property string mono: "monospace"
    readonly property string numeric: googleSansLoader.name.length > 0 ? googleSansLoader.name : "Ubuntu"
}
