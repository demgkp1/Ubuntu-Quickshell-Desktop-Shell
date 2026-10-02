pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property QtObject curves: QtObject {
        readonly property var standard: [0.2, 0, 0, 1, 1, 1]
        readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property var standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property var expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
        readonly property var clickBounce: [0.2, 0, 0, 1, 1, 1]
        readonly property var elementMoveFast: [0.2, 0, 0, 1, 1, 1]
    }

    property QtObject durations: QtObject {
        readonly property int fast: 150
        readonly property int normal: 250
        readonly property int slow: 400
        readonly property int expressiveFastSpatial: 350
        readonly property int expressiveDefaultSpatial: 450
        readonly property int elementMoveFast: 200
        readonly property int clickBounce: 180
    }

    property QtObject animation: QtObject {
        readonly property QtObject standard: QtObject {
            readonly property int duration: root.durations.normal
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.standard
        }

        readonly property QtObject expressiveDefaultSpatial: QtObject {
            readonly property int duration: root.durations.expressiveDefaultSpatial
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveDefaultSpatial
        }

        readonly property QtObject expressiveFastSpatial: QtObject {
            readonly property int duration: root.durations.expressiveFastSpatial
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.expressiveFastSpatial
        }

        readonly property QtObject elementMoveFast: QtObject {
            readonly property int duration: root.durations.elementMoveFast
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.elementMoveFast
        }

        readonly property QtObject clickBounce: QtObject {
            readonly property int duration: root.durations.clickBounce
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.clickBounce
        }

        readonly property QtObject expressiveEffects: QtObject {
            readonly property int duration: root.durations.fast
            readonly property int type: Easing.BezierSpline
            readonly property var bezierCurve: root.curves.standard
        }
    }
}
