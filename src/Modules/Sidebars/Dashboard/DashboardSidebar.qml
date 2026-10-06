import QtQuick
import qs.Common
import qs.Services
import qs.Widgets.common

Item {
    id: root

    signal presentationClosed

    property var panelScreen: null
    readonly property bool onLeft: PersonalizationConfig.dashboardSidebarSide === "left"
    property real sidebarWidth: Math.min(Metrics.sidebarWidthComfortable, Math.max(0, width))
    readonly property alias blurBackgroundItem: revealSurface.blurBackgroundItem
    readonly property bool requestedOpen: WidgetState.dashboardSidebarOpen
    property bool presentationAllowed: true
    property bool panelPresented: false
    property bool contentRetained: false
    property bool presentationOpen: false
    property bool keepLoaded: PersonalizationConfig.keepSidebarsLoaded
    property var weatherSourceOverride: null
    readonly property bool contentReady: true
    readonly property bool contentOperational: panelPresented
    readonly property string activeView: WidgetState.dashboardSidebarView
    readonly property int instantiatedViewCount: 0
    readonly property var weatherView: null

    function preparePresentation() {
        contentRetained = true;
        startPresentation();
    }

    function startPresentation() {
        if (!requestedOpen || !contentReady || !presentationAllowed)
            return;
        panelPresented = true;
        presentationOpen = true;
    }

    function beginClosing() {
        presentationOpen = false;
        if (panelPresented)
            return;
        if (!keepLoaded)
            contentRetained = false;
        root.presentationClosed();
    }

    function finishClosing() {
        if (requestedOpen)
            return;

        revealSurface.reset();
        panelPresented = false;
        if (!root.keepLoaded)
            contentRetained = false;
        root.presentationClosed();
    }

    Component.onCompleted: {
        if (requestedOpen)
            preparePresentation();
    }

    onRequestedOpenChanged: {
        if (requestedOpen)
            preparePresentation();
        else
            beginClosing();
    }

    onPresentationAllowedChanged: {
        if (presentationAllowed)
            startPresentation();
    }

    onContentReadyChanged: {
        if (contentReady)
            startPresentation();
    }

    onKeepLoadedChanged: {
        if (!root.keepLoaded && !requestedOpen && !root.panelPresented) {
            root.contentRetained = false;
        }
    }

    function containsPoint(hostX, hostY) {
        const localPosition = revealSurface.mapFromItem(root, hostX, hostY);
        return revealSurface.containsVisiblePoint(localPosition.x, localPosition.y);
    }

    EdgeRevealSurface {
        id: revealSurface

        visible: root.panelPresented
        x: root.onLeft ? 0 : root.width - root.sidebarWidth
        y: 0
        width: root.sidebarWidth
        height: root.height
        open: root.presentationOpen
        onLeft: root.onLeft
        backgroundColor: BlurService.backgroundColor(Appearance.colors.colLayer0)
        onClosed: root.finishClosing()

        Item {
            anchors.fill: parent
        }
    }
}
