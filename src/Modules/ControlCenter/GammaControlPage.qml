import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets.common

SidebarFlickable {
    id: root
    property real contentPadding: Metrics.pageMargin
    property bool searchAnchorsEnabled: true
    clip: true
    contentWidth: width
    contentHeight: content.implicitHeight + contentPadding * 2
    ColumnLayout {
        id: content
        width: Math.min(640, Math.max(0, root.width - root.contentPadding * 2))
        x: Math.max(root.contentPadding, (root.width - width) / 2)
        y: root.contentPadding
        spacing: Metrics.spacingL
        InlineStatusBanner {
            Layout.fillWidth: true
            tone: "warning"
            message: DisplayColor.error
        }
        SettingsSection {
            Layout.fillWidth: true
            title: qsTr("GNOME color management")
            iconName: "nightlight"
            SettingsRow {
                Layout.fillWidth: true
                title: qsTr("Night light")
                supportingText: qsTr("Managed by GNOME. Clavis does not apply custom gamma, contrast, dimming or location schedules.")
                trailing: ActionButton {
                    text: qsTr("Open GNOME Settings")
                    iconName: "open_in_new"
                    onClicked: Quickshell.execDetached(["gnome-control-center", "display"])
                }
            }
        }
    }
}
