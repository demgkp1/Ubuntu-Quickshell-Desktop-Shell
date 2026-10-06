import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Common
import qs.Widgets.common

PanelWindow {
    id: root

    property string edge: PersonalizationConfig.barPosition || "left"
    readonly property real visualThickness: Sizes.barVisualThickness
    readonly property real outerEdgeMargin: Sizes.barOuterEdgeMargin
    // Shadow pixels need surface space, but must not reserve desktop space.
    readonly property real surfaceThickness: outerEdgeMargin + visualThickness + Sizes.barShadowBuffer
    readonly property real exclusiveThickness: outerEdgeMargin + visualThickness

    screen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property int x: root.screen && root.screen.geometry ? root.screen.geometry.x : (root.screen ? root.screen.x : 0)
    property int y: root.screen && root.screen.geometry ? root.screen.geometry.y : (root.screen ? root.screen.y : 0)
    implicitWidth: Sizes.barVisualThickness + Sizes.barOuterEdgeMargin + Sizes.barShadowBuffer
    implicitHeight: root.screen && root.screen.geometry ? root.screen.geometry.height : (root.screen ? root.screen.height : 1080)
    color: "transparent"
    exclusiveZone: PersonalizationConfig.barOverlay ? 0 : exclusiveThickness
    // WlrLayershell attached properties suppress X11 _NET_WM_STRUT under Mutter XCB.
    // WlrLayershell.layer: WlrLayer.Top
    // WlrLayershell.namespace: "clavis-shell-bar-vertical"
    // WlrLayershell.exclusionMode: PersonalizationConfig.barOverlay ? ExclusionMode.Ignore : ExclusionMode.Normal

    BarAxis {
        id: axis

        edge: root.edge
    }

    anchors {
        top: true
        bottom: true
        left: axis.isLeft
        right: axis.isRight
    }

    Item {
        id: visualBand

        x: axis.isLeft ? root.outerEdgeMargin : Sizes.barShadowBuffer
        y: 0
        width: root.visualThickness
        height: parent.height

        VerticalBarContent {
            id: content

            anchors.fill: parent
            screen: root.screen
            axis: axis
        }
    }

    CompositorBlurRegion {
        targetWindow: root
        backgroundItem: content.backgroundItems.length > 0 ? content.backgroundItems[0] : null
        additionalBackgroundItems: content.backgroundItems.slice(1)
        radius: 18
    }

    mask: Region {
        Region {
            item: content.leadingInputRegionItem
        }

        Region {
            item: content.trailingInputRegionItem
        }

        HotCornerExclusionRegion {
            surfaceWidth: root.width
            surfaceHeight: root.height
            leftEdge: axis.isLeft
            rightEdge: axis.isRight
        }
    }
}
