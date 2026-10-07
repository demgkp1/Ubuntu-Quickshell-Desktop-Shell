import QtQuick
import QtQuick.Shapes

Item {
    id: root

    enum ShapeType {
        Square,
        Circle,
        Pill,
        Diamond,
        Gem,
        ClamShell,
        Slanted,
        Arch,
        Fan,
        Arrow,
        SemiCircle,
        Triangle,
        Pentagon,
        Sunny,
        VerySunny,
        Cookie4Sided,
        Cookie6Sided,
        Cookie7Sided,
        Cookie9Sided,
        Cookie12Sided,
        Ghostish,
        SoftBurst,
        Custom
    }

    // Static enum aliases for compatibility
    readonly property int square: MaterialShape.Square
    readonly property int circle: MaterialShape.Circle
    readonly property int pill: MaterialShape.Pill
    readonly property int diamond: MaterialShape.Diamond
    readonly property int gem: MaterialShape.Gem
    readonly property int clamShell: MaterialShape.ClamShell
    readonly property int slanted: MaterialShape.Slanted
    readonly property int arch: MaterialShape.Arch
    readonly property int fan: MaterialShape.Fan
    readonly property int arrow: MaterialShape.Arrow
    readonly property int semiCircle: MaterialShape.SemiCircle
    readonly property int triangle: MaterialShape.Triangle
    readonly property int pentagon: MaterialShape.Pentagon
    readonly property int sunny: MaterialShape.Sunny
    readonly property int verySunny: MaterialShape.VerySunny
    readonly property int cookie4Sided: MaterialShape.Cookie4Sided
    readonly property int cookie6Sided: MaterialShape.Cookie6Sided
    readonly property int cookie7Sided: MaterialShape.Cookie7Sided
    readonly property int cookie9Sided: MaterialShape.Cookie9Sided
    readonly property int cookie12Sided: MaterialShape.Cookie12Sided
    readonly property int ghostish: MaterialShape.Ghostish
    readonly property int softBurst: MaterialShape.SoftBurst
    readonly property int custom: MaterialShape.Custom

    property int shape: MaterialShape.Square
    property int shapeId: shape
    property color color: "transparent"
    property real implicitSize: 48
    property color strokeColor: "transparent"
    property real strokeWidth: 0
    property real animationDuration: 300
    property int animationEasing: Easing.InOutQuad
    property var customShape: null

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    function star(points, innerRadius, cornerRadius, rotation) {
        return null;
    }

    function regularPolygon(points) {
        return null;
    }

    Rectangle {
        id: visualShape
        anchors.fill: parent
        color: root.color
        border.color: root.strokeColor
        border.width: root.strokeWidth
        radius: {
            const effectiveShape = (root.shapeId !== MaterialShape.Square && root.shape === MaterialShape.Square) ? root.shapeId : root.shape;
            switch (effectiveShape) {
            case MaterialShape.Circle:
                return Math.min(width, height) / 2;
            case MaterialShape.Pill:
                return Math.min(width, height) / 2;
            case MaterialShape.Square:
                return 4;
            case MaterialShape.Cookie4Sided:
            case MaterialShape.Cookie6Sided:
            case MaterialShape.Cookie7Sided:
            case MaterialShape.Cookie9Sided:
            case MaterialShape.Cookie12Sided:
                return Math.min(width, height) * 0.28;
            case MaterialShape.SoftBurst:
            case MaterialShape.Sunny:
            case MaterialShape.VerySunny:
                return Math.min(width, height) * 0.35;
            case MaterialShape.Ghostish:
            case MaterialShape.Arch:
            case MaterialShape.Slanted:
            case MaterialShape.Gem:
            case MaterialShape.Diamond:
            case MaterialShape.ClamShell:
            case MaterialShape.Pentagon:
            default:
                return Math.min(width, height) * 0.2;
            }
        }
    }
}
