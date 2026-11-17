import QtQuick
import Quickshell
import Quickshell.Wayland
import Clavis.Runtime
import qs.Services
import qs.Common
import qs.Widgets.common

Scope {
    id: root

    property var screen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property string edge: PersonalizationConfig.barPosition || "left"
    readonly property bool useWlrLayershell: CompositorBackend.name === "niri"

    function placementSnapshot() {
        const win = root.useWlrLayershell
            ? (niriVariants.instances.length > 0 ? niriVariants.instances[0] : null)
            : (x11Variants.instances.length > 0 ? x11Variants.instances[0] : null);
        return win ? win.placementSnapshot() : ({role: "bar", orientation: "vertical", available: false});
    }

    component BaseVerticalBarWindow: PanelWindow {
        id: barWindow

        property string edge: root.edge
        readonly property real visualThickness: Sizes.barVisualThickness
        readonly property real outerEdgeMargin: Sizes.barOuterEdgeMargin
        // Shadow pixels need surface space, but must not reserve desktop space.
        readonly property real surfaceThickness: outerEdgeMargin + visualThickness + Sizes.barShadowBuffer
        readonly property real exclusiveThickness: outerEdgeMargin + visualThickness
        readonly property real gnomePanelOffset: 0
        readonly property real screenX: barWindow.screen && barWindow.screen.geometry
            ? barWindow.screen.geometry.x : (barWindow.screen ? barWindow.screen.x : 0)
        readonly property real screenY: barWindow.screen && barWindow.screen.geometry
            ? barWindow.screen.geometry.y : (barWindow.screen ? barWindow.screen.y : 0)
        readonly property real screenWidth: barWindow.screen && barWindow.screen.geometry
            ? barWindow.screen.geometry.width : (barWindow.screen ? barWindow.screen.width : 1920)
        readonly property real screenHeight: barWindow.screen && barWindow.screen.geometry
            ? barWindow.screen.geometry.height : (barWindow.screen ? barWindow.screen.height : 1080)

        screen: root.screen
        implicitWidth: Sizes.barVisualThickness + Sizes.barOuterEdgeMargin + Sizes.barShadowBuffer
        implicitHeight: barWindow.screenHeight
        color: "transparent"
        exclusiveZone: PersonalizationConfig.barOverlay ? 0 : barWindow.exclusiveThickness
        margins.top: barWindow.gnomePanelOffset

        PanelReservation {
            id: reservation
            target: barWindow.contentItem
            edge: barWindow.edge
            thickness: PersonalizationConfig.barOverlay ? 0 : barWindow.exclusiveThickness
        }

        function placementSnapshot() {
            return Object.assign({role: "bar", orientation: "vertical"}, reservation.inspect(visualBand));
        }

        BarAxis {
            id: axis

            edge: barWindow.edge
        }

        anchors {
            top: true
            bottom: true
            left: axis.isLeft
            right: axis.isRight
        }

        Item {
            id: visualBand

            x: axis.isLeft ? barWindow.outerEdgeMargin : Sizes.barShadowBuffer
            y: 0
            width: barWindow.visualThickness
            height: barWindow.height

            VerticalBarContent {
                id: content

                anchors.fill: parent
                screen: barWindow.screen
                axis: axis
            }
        }

        CompositorBlurRegion {
            targetWindow: barWindow
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
                surfaceWidth: barWindow.width
                surfaceHeight: barWindow.height
                leftEdge: axis.isLeft
                rightEdge: axis.isRight
            }
        }
    }

    // Separate Variants keep WlrLayershell attached properties completely absent on GNOME/X11,
    // preventing Mutter XCB from suppressing _NET_WM_STRUT_PARTIAL.
    Variants {
        id: x11Variants
        model: !root.useWlrLayershell ? [0] : []

        BaseVerticalBarWindow {
            required property int modelData
        }
    }

    Variants {
        id: niriVariants
        model: root.useWlrLayershell ? [0] : []

        BaseVerticalBarWindow {
            required property int modelData

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "clavis-shell-bar-vertical"
            WlrLayershell.exclusionMode: PersonalizationConfig.barOverlay ? ExclusionMode.Ignore : ExclusionMode.Normal
        }
    }
}
