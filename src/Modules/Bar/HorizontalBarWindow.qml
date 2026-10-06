import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Common
import qs.Widgets.common

PanelWindow {
    id: root

    property string edge: PersonalizationConfig.barPosition || "top"
    readonly property real visualThickness: Sizes.barVisualThickness
    readonly property real outerEdgeMargin: Sizes.barOuterEdgeMargin
    // Shadow pixels need surface space, but must not reserve desktop space.
    readonly property real surfaceThickness: outerEdgeMargin + visualThickness + Sizes.barShadowBuffer
    readonly property real exclusiveThickness: outerEdgeMargin + visualThickness

    screen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property int x: root.screen && root.screen.geometry ? root.screen.geometry.x : (root.screen ? root.screen.x : 0)
    property int y: root.screen && root.screen.geometry ? root.screen.geometry.y : (root.screen ? root.screen.y : 0)
    implicitWidth: root.screen && root.screen.geometry ? root.screen.geometry.width : (root.screen ? root.screen.width : 1920)
    implicitHeight: Sizes.barVisualThickness + Sizes.barOuterEdgeMargin + Sizes.barShadowBuffer
    color: "transparent"
    exclusiveZone: PersonalizationConfig.barOverlay ? 0 : exclusiveThickness
    // WlrLayershell attached properties suppress X11 _NET_WM_STRUT under Mutter XCB,
    // which causes Mutter to center the bar at Y: 532 instead of docking at Y: 0.
    // WlrLayershell.layer: WlrLayer.Top
    // WlrLayershell.namespace: "clavis-shell-bar-horizontal"
    // WlrLayershell.exclusionMode: PersonalizationConfig.barOverlay ? ExclusionMode.Ignore : ExclusionMode.Normal

    BarAxis {
        id: axis

        edge: root.edge
    }

    anchors {
        left: true
        right: true
        top: true
        bottom: false
    }

    Item {
        id: visualBand

        x: 0
        y: axis.isTop ? root.outerEdgeMargin : Sizes.barShadowBuffer
        width: root.width
        height: root.visualThickness

        HorizontalBarContent {
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
            topEdge: axis.isTop
            bottomEdge: axis.isBottom
        }
    }
}
