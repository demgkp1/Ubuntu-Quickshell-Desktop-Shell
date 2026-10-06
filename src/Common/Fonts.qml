pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // User-configurable family defaults. Keep all family literals in this
    // singleton so components only depend on semantic roles.
    readonly property string bundledFamilyName: bundledFont.name || "Google Sans Flex"
    readonly property string defaultUi: root.familyAvailable("LXGW WenKai GB Screen")
                                         ? "LXGW WenKai GB Screen"
                                         : (root.familyAvailable(root.bundledFamilyName)
                                            ? root.bundledFamilyName
                                            : (root.familyAvailable("Ubuntu Sans")
                                               ? "Ubuntu Sans"
                                               : (root.familyAvailable("Ubuntu")
                                                  ? "Ubuntu"
                                                  : "sans-serif")))
    readonly property string defaultMono: root.familyAvailable("JetBrainsMono Nerd Font")
                                           ? "JetBrainsMono Nerd Font"
                                           : (root.familyAvailable("Ubuntu Sans Mono")
                                              ? "Ubuntu Sans Mono"
                                              : (root.familyAvailable("Ubuntu Mono")
                                                 ? "Ubuntu Mono"
                                                 : "monospace"))
    readonly property string defaultNumeric: root.defaultMono
    // These preferences are deliberately separate from the effective family
    // properties below. An unavailable saved family is retained for the next
    // run while rendering falls back safely.
    property string configuredUi: ""
    property string configuredMono: ""
    property string configuredNumeric: ""
    property string configuredExpressive: ""
    readonly property string ui: root.resolveFamily(root.configuredUi, root.defaultUi, "sans-serif")
    readonly property string mono: root.resolveFamily(root.configuredMono, root.defaultMono, "monospace")
    readonly property string numeric: root.resolveFamily(root.configuredNumeric, root.defaultNumeric,
                                                         root.mono)
    readonly property string expressive: root.resolveFamily(root.configuredExpressive, root.bundledFamilyName,
                                                            root.ui)
    // This role is intentionally independent of every user preference. If
    // the bundled file cannot load, Qt's normal font fallback still applies
    // to this family name; the clock must never switch to a user-selected
    // family.
    readonly property string systemClock: root.bundledFamilyName
    readonly property string materialSymbolsRounded: "Material Symbols Rounded"
    readonly property string materialSymbolsOutlined: root.familyAvailable("Material Symbols Outlined")
                                                      ? "Material Symbols Outlined" : root.materialSymbolsRounded

    function familyAvailable(family) {
        const value = String(family || "").trim();
        if (value === "")
            return false;

        if (value === root.bundledFamilyName || (bundledFont.name && value === bundledFont.name))
            return bundledFont.status === FontLoader.Ready;

        return Qt.fontFamilies().indexOf(value) !== -1;
    }

    function resolveFamily(preferred, fallback, genericFallback) {
        const selected = String(preferred || "").trim();
        if (root.familyAvailable(selected))
            return selected;

        const defaultValue = String(fallback || "").trim();
        if (root.familyAvailable(defaultValue))
            return defaultValue;

        return genericFallback || "sans-serif";
    }

    function setConfiguredFamily(role, family) {
        const value = String(family || "").trim();
        if (role === "ui")
            root.configuredUi = value;
        else if (role === "mono")
            root.configuredMono = value;
        else if (role === "numeric")
            root.configuredNumeric = value;
        else if (role === "expressive")
            root.configuredExpressive = value;
        else
            return false;
        return true;
    }

    function setConfiguredFamilies(ui, mono, numeric, expressive) {
        root.configuredUi = String(ui || "").trim();
        root.configuredMono = String(mono || "").trim();
        root.configuredNumeric = String(numeric || "").trim();
        root.configuredExpressive = String(expressive || "").trim();
    }

    // Canvas accepts a CSS font-family string rather than a QML family
    // property. Keep the quoting in one place so a family selected by the
    // user cannot break the drawing command.
    function cssFamily(family) {
        return "\"" + String(family || "").replace(/\\/g, "\\\\").replace(/\"/g, "\\\"") + "\"";
    }

    FontLoader {
        id: bundledFont

        source: Paths.fileUrl(Paths.fontsDir + "/google-sans-flex/" + "GoogleSansFlex-VariableFont_"
                              + "GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }
}
