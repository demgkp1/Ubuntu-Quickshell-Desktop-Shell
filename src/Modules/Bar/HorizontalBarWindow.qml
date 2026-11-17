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
    property string edge: PersonalizationConfig.barPosition || "top"
    readonly property bool useWlrLayershell: CompositorBackend.name === "niri"

    function placementSnapshot() {
        const win = root.useWlrLayershell
            ? (niriVariants.instances.length > 0 ? niriVariants.instances[0] : null)
            : (x11Variants.instances.length > 0 ? x11Variants.instances[0] : null);
        return win ? win.placementSnapshot() : ({role: "bar", orientation: "horizontal", available: false});
    }

    component BaseHorizontalBarWindow: PanelWindow {
        id: barWindow

        property string edge: root.edge
        readonly property real visualThickness: Sizes.barVisualThickness
        readonly property real outerEdgeMargin: Sizes.barOuterEdgeMargin
        // Shadow pixels need surface space, but must not reserve desktop space.
        readonly property real surfaceThickness: outerEdgeMargin + visualThickness + Sizes.barShadowBuffer
        readonly property real exclusiveThickness: outerEdgeMargin + visualThickness
        readonly property real screenX: barWindow.screen && barWindow.screen.geometry
            ? barWindow.screen.geometry.x : (barWindow.screen ? barWindow.screen.x : 0)
        readonly property real screenY: barWindow.screen && barWindow.screen.geometry
            ? barWindow.screen.geometry.y : (barWindow.screen ? barWindow.screen.y : 0)
        readonly property real screenWidth: barWindow.screen && barWindow.screen.geometry
            ? barWindow.screen.geometry.width : (barWindow.screen ? barWindow.screen.width : 1920)
        readonly property real screenHeight: barWindow.screen && barWindow.screen.geometry
            ? barWindow.screen.geometry.height : (barWindow.screen ? barWindow.screen.height : 1080)

        screen: root.screen
        implicitWidth: barWindow.screenWidth
        implicitHeight: Sizes.barVisualThickness + Sizes.barOuterEdgeMargin + Sizes.barShadowBuffer
        color: "transparent"
        exclusiveZone: PersonalizationConfig.barOverlay ? 0 : barWindow.exclusiveThickness

        BarAxis {
            id: axis

            edge: barWindow.edge
        }

        readonly property real gnomePanelOffset: CompositorBackend.name !== "niri" && axis.isTop
                && CompositorBackend.connected
                && CompositorBackend.outputs.some(output => output.primary && barWindow.screen
                                                  && output.name === barWindow.screen.name)
                ? Number(GnomeSession.snapshot.panelHeight || 0) : 0
        margins.top: barWindow.gnomePanelOffset

        // Qt uses logical coordinates; EWMH struts are native X11 root pixels.
        // Keep Quickshell's logical panel stack but correct only our own strut on GNOME/X11.
        PanelReservation {
            id: reservation
            target: barWindow.contentItem
            edge: barWindow.edge
            thickness: PersonalizationConfig.barOverlay ? 0 : barWindow.exclusiveThickness + barWindow.gnomePanelOffset
        }

        function placementSnapshot() {
            return Object.assign({role: "bar", orientation: "horizontal"}, reservation.inspect(visualBand));
        }

        anchors {
            left: true
            right: true
            top: axis.isTop
            bottom: axis.isBottom
        }

        Item {
            id: visualBand

            x: 0
            y: axis.isTop ? barWindow.outerEdgeMargin : Sizes.barShadowBuffer
            width: barWindow.width
            height: barWindow.visualThickness

            HorizontalBarContent {
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
                topEdge: axis.isTop
                bottomEdge: axis.isBottom
            }
        }
    }

    // Separate Variants keep WlrLayershell attached properties completely absent on GNOME/X11,
    // preventing Mutter XCB from suppressing _NET_WM_STRUT_PARTIAL.
    Variants {
        id: x11Variants
        model: !root.useWlrLayershell ? [0] : []

        BaseHorizontalBarWindow {
            required property int modelData
        }
    }

    Variants {
        id: niriVariants
        model: root.useWlrLayershell ? [0] : []

        BaseHorizontalBarWindow {
            required property int modelData

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "clavis-shell-bar-horizontal"
            WlrLayershell.exclusionMode: PersonalizationConfig.barOverlay ? ExclusionMode.Ignore : ExclusionMode.Normal
        }
    }
}
