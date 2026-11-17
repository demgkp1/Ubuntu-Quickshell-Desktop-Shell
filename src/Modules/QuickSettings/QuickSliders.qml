import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets.common

Rectangle {
    id: root

    readonly property real gammaCutoff: 0.3
    property var screen: null
    property bool detailed: false
    property real pullExpansion: 0
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property real brightnessValue: brightnessMonitor ? brightnessMonitor.brightness :
                                                                Brightness.brightnessValue
    property real verticalPadding: detailed ? Metrics.spacingL : 4
    property real horizontalPadding: detailed ? Metrics.spacingL : 12

    Layout.fillWidth: true
    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    border.color: Appearance.colors.colLayer0Border
    border.width: 1

    ColumnLayout {
        id: contentItem

        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }
        spacing: (root.detailed ? Metrics.spacingS : 0) + root.pullExpansion

        SliderHeading {
            visible: root.detailed
            title: qsTr("Brightness")
            detail: root.screen ? root.screen.name : ""
        }

        QuickMaterialSlider {
            Accessible.name: qsTr("Brightness")
            materialSymbol: "light_mode"
            enabled: Brightness.available
            value: root.brightnessValue
            percentText: Brightness.available ? Math.round(value * 100) + "%" : qsTr("Unavailable")
            tooltipContent: Brightness.available ? percentText : qsTr("No hardware backlight; GNOME software dimming is unavailable")
            onMoved: Brightness.setBrightnessForScreen(root.screen, value)

        }

        SliderHeading {
            visible: root.detailed
            Layout.topMargin: (root.detailed ? Metrics.spacingS : 0) + root.pullExpansion * 1.5
            title: qsTr("Sound")
            detail: Volume.sinkName
        }

        QuickMaterialSlider {
            Accessible.name: qsTr("Sound")
            enabled: Volume.outputAvailable
            materialSymbol: Volume.sinkMuted ? "volume_off" : "volume_up"
            value: Volume.sinkVolume
            percentText: !Volume.outputAvailable ? qsTr("Unavailable") : Volume.sinkMuted ? qsTr("Muted") : Math.round(value * 100) + "%"
            onMoved: Volume.setSinkVolume(value)
        }

        SliderHeading {
            visible: root.detailed
            Layout.topMargin: (root.detailed ? Metrics.spacingS : 0) + root.pullExpansion * 1.5
            title: qsTr("Microphone")
            detail: Volume.sourceName
        }

        QuickMaterialSlider {
            Accessible.name: qsTr("Microphone")
            enabled: Volume.inputAvailable
            materialSymbol: Volume.sourceMuted ? "mic_off" : "mic"
            value: Volume.sourceVolume
            percentText: !Volume.inputAvailable ? qsTr("Unavailable") : Volume.sourceMuted ? qsTr("Muted") : Math.round(value * 100) + "%"
            onMoved: Volume.setSourceVolume(value)
        }

        SliderHeading {
            visible: root.detailed && CompositorBackend.supportsWindowOpacity
            Layout.topMargin: (root.detailed ? Metrics.spacingS : 0) + root.pullExpansion * 1.5
            title: qsTr("Window opacity")
            detail: PersonalizationConfig.windowOpacityEnabled
                ? qsTr("Focused %1% · Unfocused %2%")
                    .arg(Math.round(PersonalizationConfig.activeWindowOpacity * 100))
                    .arg(Math.round(PersonalizationConfig.inactiveWindowOpacity * 100))
                : qsTr("Off")
        }

        QuickMaterialSlider {
            id: windowOpacitySlider

            readonly property bool opacityActive: PersonalizationConfig.windowOpacityEnabled

            visible: CompositorBackend.supportsWindowOpacity
            enabled: CompositorBackend.supportsWindowOpacity
            Accessible.name: qsTr("Window opacity")
            materialSymbol: opacityActive ? "opacity" : "layers_clear"
            animateWave: false
            from: 0.2
            to: 1.0
            stepSize: 0.01
            value: PersonalizationConfig.activeWindowOpacity
            percentText: opacityActive ? Math.round(value * 100) + "%" : qsTr("Off")
            tooltipContent: opacityActive
                ? Math.round(value * 100) + "%"
                : qsTr("Window transparency off (click icon to enable)")
            highlightColor: opacityActive ? Appearance.colors.colPrimary : Appearance.colors.colOutline
            handleColor: opacityActive ? Appearance.colors.colPrimary : Appearance.colors.colOutline
            onMoved: PersonalizationConfig.setActiveWindowOpacity(value)

            MouseArea {
                id: opacityIconToggleArea

                x: Math.max(0, (windowOpacitySlider.value >= 0.9 && windowOpacitySlider.handle
                    ? (windowOpacitySlider.handle.x + windowOpacitySlider.handle.width - 14)
                    : (windowOpacitySlider.width - 8)) - 26)
                y: 0
                width: 32
                height: parent.height
                z: 2
                enabled: windowOpacitySlider.enabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: PersonalizationConfig.setWindowOpacityEnabled(!PersonalizationConfig.windowOpacityEnabled)

                StyledToolTip {
                    extraVisibleCondition: opacityIconToggleArea.containsMouse
                    text: windowOpacitySlider.opacityActive
                        ? qsTr("Disable window transparency")
                        : qsTr("Enable window transparency")
                }
            }
        }
    }

    component SliderHeading: ColumnLayout {
        id: heading
        property string title: ""
        property string detail: ""
        Layout.fillWidth: true
        spacing: Metrics.spacingXXS + root.pullExpansion * 0.5
        Text {
            Layout.fillWidth: true
            text: heading.title
            color: Appearance.colors.colOnSurface
            font.family: Typography.titleSmall.family
            font.pixelSize: Typography.titleSmall.pixelSize
            font.weight: Typography.titleSmall.weight
        }
        Text {
            Layout.fillWidth: true
            text: heading.detail
            visible: text.length > 0
            elide: Text.ElideRight
            color: Appearance.colors.colOnSurfaceVariant
            font.family: Typography.bodySmall.family
            font.pixelSize: Typography.bodySmall.pixelSize
        }
    }
}
