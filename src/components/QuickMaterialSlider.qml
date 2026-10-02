import QtQuick
import QtQuick.Layouts
import "../common"

RowLayout {
    id: root

    property string materialSymbol: "volume_up"
    property real value: 0.5
    property string percentText: `${Math.round(value * 100)}%`
    property bool enabled: true

    signal moved(real newValue)

    spacing: 8
    Layout.fillWidth: true

    // 1. Left Value Pill
    Rectangle {
        Layout.preferredWidth: 68
        Layout.preferredHeight: 36
        radius: 18
        color: root.value > 0 ? Appearance.colors.colPrimary : Appearance.colors.colLayer2

        Row {
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: root.percentText
                color: root.value > 0 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                font.family: Fonts.numeric
                font.pixelSize: 12
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }

            MaterialSymbol {
                text: root.materialSymbol
                iconSize: 14
                fill: 1
                color: root.value > 0 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // 2. Right Interactive Split Slider
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 36

        MaterialSplitSlider {
            id: slider
            anchors.fill: parent
            value: root.value
            enabled: root.enabled
            highlightColor: Appearance.colors.colPrimary
            trackColor: Appearance.colors.colLayer2
            handleColor: Appearance.colors.colPrimary
            trackHeight: 36
            trackRadius: 18

            onMoved: {
                root.value = slider.value;
                root.moved(slider.value);
            }
        }

        // Right Trailing Symbol inside slider
        MaterialSymbol {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.materialSymbol
            iconSize: 18
            color: slider.visualPosition >= 0.92 
                ? Appearance.colors.colOnPrimary 
                : Appearance.colors.colOnLayer2
        }
    }
}
