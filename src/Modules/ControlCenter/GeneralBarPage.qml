import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Common
import qs.Components
import qs.Services
import qs.Widgets.common

StyledFlickable {
    id: root

    readonly property bool horizontalBar: PersonalizationConfig.barPosition === "top"
                                          || PersonalizationConfig.barPosition === "bottom"

    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + Metrics.pageMargin * 2

    ColumnLayout {
        id: contentColumn

        width: Math.min(680, Math.max(0, root.width - Metrics.pageMargin * 2))
        x: Math.max(Metrics.pageMargin, (root.width - width) / 2)
        y: Metrics.pageMargin
        spacing: Metrics.spacingL

        // Section 0: Position & Basic Settings
        SettingsSection {
            id: searchSection0
            Layout.fillWidth: true
            flat: true
            title: searchAnchor0.title
            SettingsSearchAnchor {
                id: searchAnchor0
                target: searchSection0
                declaration:
                    '{"id":"general.bar.section.position","route":"general.bar","title":"Position","context":"GeneralBarPage","icon":"dock_to_bottom","aliases":[]}'
            }
            iconName: "dock_to_bottom"

            SettingsRow {
                Layout.fillWidth: true
                title: qsTr("Show bar")
                supportingText: qsTr("Toggle visibility of the main desktop top/edge status bar")
                trailing: StyledSwitch {
                    checked: PersonalizationConfig.barEnabled
                    Accessible.name: qsTr("Show bar")
                    onToggled: PersonalizationConfig.setValue("barEnabled", checked)
                }
            }

            SettingsRow {
                Layout.fillWidth: true
                title: qsTr("Floating")
                supportingText: qsTr("Add floating margins and curved borders around the bar")
                trailing: StyledSwitch {
                    checked: PersonalizationConfig.barOverlay
                    Accessible.name: qsTr("Floating")
                    onToggled: PersonalizationConfig.setValue("barOverlay", checked)
                }
            }

            SettingsRow {
                Layout.fillWidth: true
                title: qsTr("Screen edge")
                supportingText: qsTr("Choose the monitor edge where the status bar is placed")
                trailing: EdgePositionSelector {
                    position: PersonalizationConfig.barPosition
                    onPositionSelected: position => {
                        return PersonalizationConfig.setBarPosition(position);
                    }
                }
            }

            SettingsRow {
                Layout.fillWidth: true
                title: qsTr("Show device names")
                supportingText: qsTr("Show friendly hardware device names in status bar indicators")
                trailing: StyledSwitch {
                    checked: PersonalizationConfig.barShowNames
                    Accessible.name: qsTr("Show device names")
                    onToggled: PersonalizationConfig.setBarShowNames(checked)
                }
            }

            SettingsRow {
                Layout.fillWidth: true
                title: qsTr("Show numeric values")
                supportingText: qsTr("Display real-time numerical readings on indicators and monitors")
                trailing: StyledSwitch {
                    checked: PersonalizationConfig.barShowValues
                    Accessible.name: qsTr("Show numeric values")
                    onToggled: PersonalizationConfig.setBarShowValues(checked)
                }
            }
        }

        // Section 1: Components and Visual Layout
        SettingsSection {
            id: searchSection1
            Layout.fillWidth: true
            flat: true
            title: searchAnchor1.title
            SettingsSearchAnchor {
                id: searchAnchor1
                target: searchSection1
                declaration:
                    '{"id":"general.bar.section.components","route":"general.bar","title":"Components","context":"GeneralBarPage","icon":"dock_to_bottom","aliases":[]}'
            }
            iconName: "view_agenda"

            // Live Bar Preview Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: previewColumn.implicitHeight + Metrics.spacingM * 2
                radius: Metrics.cornerL
                color: Appearance.colors.colLayer1
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant

                ColumnLayout {
                    id: previewColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Metrics.spacingM
                    }
                    spacing: Metrics.spacingS

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingS

                        MaterialSymbol {
                            text: "preview"
                            iconSize: Metrics.iconS
                            color: Appearance.colors.colPrimary
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: qsTr("Live bar preview")
                            color: Appearance.colors.colOnSurface
                            font.family: Fonts.ui
                            font.pixelSize: Typography.titleSmall.pixelSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        ActionButton {
                            iconName: "restart_alt"
                            text: qsTr("Reset layout")
                            onClicked: PersonalizationConfig.resetBarLayout()
                        }
                    }

                    // Simulated bar container
                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: Appearance.rounding.large
                        color: Appearance.colors.colSurfaceContainerHigh
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant
                        clip: true

                        RowLayout {
                            id: simBarRow

                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingM
                            anchors.rightMargin: Metrics.spacingM
                            spacing: Metrics.spacingXS

                            // Left components pills
                            RowLayout {
                                Layout.minimumWidth: 0
                                Layout.maximumWidth: Math.max(0, Math.floor((simBarRow.width - centerClockPill.width) / 2 - Metrics.spacingXS * 2))
                                Layout.preferredWidth: Math.min(implicitWidth, Layout.maximumWidth)
                                spacing: 6
                                clip: true

                                Repeater {
                                    model: PersonalizationConfig.barLeadingComponents
                                    delegate: Rectangle {
                                        readonly property var compInfo: PersonalizationConfig.barComponentInfo(modelData)
                                        Layout.preferredHeight: 32
                                        Layout.minimumWidth: 32
                                        Layout.maximumWidth: 110
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: Math.min(110, Math.max(38, previewLeftIcon.implicitWidth + previewLeftText.implicitWidth + 18))
                                        radius: Appearance.rounding.full
                                        color: Appearance.colors.colSecondaryContainer
                                        clip: true

                                        RowLayout {
                                            id: previewLeftRow
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                                leftMargin: 7
                                                rightMargin: 7
                                            }
                                            spacing: 4
                                            MaterialSymbol {
                                                id: previewLeftIcon
                                                text: compInfo.icon || "widgets"
                                                iconSize: 15
                                                color: Appearance.colors.colOnSecondaryContainer
                                            }
                                            Text {
                                                id: previewLeftText
                                                Layout.fillWidth: true
                                                Layout.minimumWidth: 0
                                                text: compInfo.label.split(" ")[0]
                                                color: Appearance.colors.colOnSecondaryContainer
                                                font.pixelSize: 11
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Center Keystone mock
                            Rectangle {
                                id: centerClockPill
                                Layout.preferredHeight: 32
                                Layout.preferredWidth: 84
                                radius: Appearance.rounding.full
                                color: Appearance.colors.colPrimaryContainer

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "schedule"
                                        iconSize: 15
                                        color: Appearance.colors.colOnPrimaryContainer
                                    }
                                    Text {
                                        text: "12:00"
                                        color: Appearance.colors.colOnPrimaryContainer
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Right components pills
                            RowLayout {
                                Layout.minimumWidth: 0
                                Layout.maximumWidth: Math.max(0, Math.floor((simBarRow.width - centerClockPill.width) / 2 - Metrics.spacingXS * 2))
                                Layout.preferredWidth: Math.min(implicitWidth, Layout.maximumWidth)
                                spacing: 6
                                clip: true

                                Repeater {
                                    model: PersonalizationConfig.barTrailingComponents
                                    delegate: Rectangle {
                                        readonly property var compInfo: PersonalizationConfig.barComponentInfo(modelData)
                                        Layout.preferredHeight: 32
                                        Layout.minimumWidth: 32
                                        Layout.maximumWidth: 110
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: Math.min(110, Math.max(38, previewRightIcon.implicitWidth + previewRightText.implicitWidth + 18))
                                        radius: Appearance.rounding.full
                                        color: Appearance.colors.colSecondaryContainer
                                        clip: true

                                        RowLayout {
                                            id: previewRightRow
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                                leftMargin: 7
                                                rightMargin: 7
                                            }
                                            spacing: 4
                                            MaterialSymbol {
                                                id: previewRightIcon
                                                text: compInfo.icon || "widgets"
                                                iconSize: 15
                                                color: Appearance.colors.colOnSecondaryContainer
                                            }
                                            Text {
                                                id: previewRightText
                                                Layout.fillWidth: true
                                                Layout.minimumWidth: 0
                                                text: compInfo.label.split(" ")[0]
                                                color: Appearance.colors.colOnSecondaryContainer
                                                font.pixelSize: 11
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Left / Leading Zone Section
            SettingsSection {
                Layout.fillWidth: true
                flat: false
                title: root.horizontalBar ? qsTr("Left zone components") : qsTr("Top zone components")
                iconName: root.horizontalBar ? "align_horizontal_left" : "align_vertical_top"
                supportingText: PersonalizationConfig.barLeadingComponents.length === 1
                                ? qsTr("1 component enabled. Use the arrows to reorder, move across zones, or remove.")
                                : qsTr("%1 components enabled. Use the arrows to reorder, move across zones, or remove.").arg(PersonalizationConfig.barLeadingComponents.length)

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Metrics.spacingS

                    // List of leading items
                    Repeater {
                        model: PersonalizationConfig.barLeadingComponents
                        delegate: Rectangle {
                            id: leadingItemCard
                            Layout.fillWidth: true
                            implicitHeight: leadingItemRow.implicitHeight + Metrics.spacingM * 2
                            radius: Metrics.cornerM
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: Appearance.colors.colOutlineVariant

                            readonly property var info: PersonalizationConfig.barComponentInfo(modelData)

                            RowLayout {
                                id: leadingItemRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: Metrics.spacingM
                                }
                                spacing: Metrics.spacingM

                                // Index badge
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: Appearance.rounding.full
                                    color: Appearance.colors.colSecondaryContainer

                                    Text {
                                        anchors.centerIn: parent
                                        text: String(index + 1)
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                }

                                // Icon
                                Rectangle {
                                    Layout.preferredWidth: 38
                                    Layout.preferredHeight: 38
                                    radius: Metrics.cornerS
                                    color: Appearance.colors.colPrimaryContainer

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: leadingItemCard.info.icon || "widgets"
                                        iconSize: 20
                                        color: Appearance.colors.colOnPrimaryContainer
                                    }
                                }

                                // Title & Description
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    spacing: 3

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Metrics.spacingS
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                            text: leadingItemCard.info.label
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnSurface
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        Rectangle {
                                            visible: leadingItemCard.info.tag.length > 0
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: Math.min(100, tagText.implicitWidth + 12)
                                            Layout.maximumWidth: 100
                                            radius: 4
                                            color: Appearance.colors.colSurfaceContainerHigh
                                            clip: true

                                            Text {
                                                id: tagText
                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    verticalCenter: parent.verticalCenter
                                                    leftMargin: 6
                                                    rightMargin: 6
                                                }
                                                horizontalAlignment: Text.AlignHCenter
                                                text: leadingItemCard.info.tag
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                                color: Appearance.colors.colOnSurfaceVariant
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: leadingItemCard.info.description
                                        font.pixelSize: 12
                                        color: Appearance.colors.colOnSurfaceVariant
                                        wrapMode: Text.Wrap
                                    }
                                }

                                // Actions
                                RowLayout {
                                    spacing: Metrics.spacingXXS

                                    IconButton {
                                        iconName: root.horizontalBar ? "arrow_back" : "arrow_upward"
                                        tooltipText: root.horizontalBar ? qsTr("Move left") : qsTr("Move up")
                                        enabled: index > 0
                                        variant: "standard"
                                        onClicked: PersonalizationConfig.moveBarComponent(modelData, "leading", index - 1)
                                    }

                                    IconButton {
                                        iconName: root.horizontalBar ? "arrow_forward" : "arrow_downward"
                                        tooltipText: root.horizontalBar ? qsTr("Move right") : qsTr("Move down")
                                        enabled: index < PersonalizationConfig.barLeadingComponents.length - 1
                                        variant: "standard"
                                        onClicked: PersonalizationConfig.moveBarComponent(modelData, "leading", index + 1)
                                    }

                                    IconButton {
                                        iconName: root.horizontalBar ? "swap_horiz" : "swap_vert"
                                        tooltipText: root.horizontalBar ? qsTr("Move to right zone") : qsTr("Move to bottom zone")
                                        variant: "tonal"
                                        onClicked: PersonalizationConfig.moveBarComponent(modelData, "trailing", PersonalizationConfig.barTrailingComponents.length)
                                    }

                                    IconButton {
                                        iconName: "close"
                                        tooltipText: qsTr("Remove")
                                        variant: "standard"
                                        onClicked: PersonalizationConfig.removeBarComponent(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Empty state
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: Metrics.cornerM
                        color: Appearance.colors.colLayer2
                        visible: PersonalizationConfig.barLeadingComponents.length === 0

                        Text {
                            anchors.centerIn: parent
                            width: Math.max(0, parent.width - Metrics.spacingM * 2)
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.horizontalBar ? qsTr("No left-zone components. Select an item below to add one.") : qsTr("No top-zone components. Select an item below to add one.")
                            color: Appearance.colors.colOnSurfaceVariant
                            font.pixelSize: 12
                        }
                    }

                    // Available to add
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingXS
                        readonly property var available: {
                            const leading = PersonalizationConfig.barLeadingComponents;
                            return PersonalizationConfig.barComponentIds.filter(id => leading.indexOf(id) === -1);
                        }
                        visible: available.length > 0

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: root.horizontalBar ? qsTr("Add component to left zone:") : qsTr("Add component to top zone:")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: Metrics.spacingS

                            Repeater {
                                model: parent.parent.available
                                delegate: ActionButton {
                                    readonly property var addInfo: PersonalizationConfig.barComponentInfo(modelData)
                                    readonly property bool isInTrailing: PersonalizationConfig.barTrailingComponents.indexOf(modelData) !== -1
                                    iconName: addInfo.icon || "widgets"
                                    text: isInTrailing ? (root.horizontalBar ? qsTr("%1 (from right)").arg(addInfo.label) : qsTr("%1 (from bottom)").arg(addInfo.label)) : qsTr("+ %1").arg(addInfo.label)
                                    onClicked: PersonalizationConfig.moveBarComponent(modelData, "leading", PersonalizationConfig.barLeadingComponents.length)
                                }
                            }
                        }
                    }
                }
            }

            // Right / Trailing Zone Section
            SettingsSection {
                Layout.fillWidth: true
                flat: false
                title: root.horizontalBar ? qsTr("Right zone components") : qsTr("Bottom zone components")
                iconName: root.horizontalBar ? "align_horizontal_right" : "align_vertical_bottom"
                supportingText: PersonalizationConfig.barTrailingComponents.length === 1
                                ? qsTr("1 component enabled. Use the arrows to reorder, move across zones, or remove.")
                                : qsTr("%1 components enabled. Use the arrows to reorder, move across zones, or remove.").arg(PersonalizationConfig.barTrailingComponents.length)

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Metrics.spacingS

                    // List of trailing items
                    Repeater {
                        model: PersonalizationConfig.barTrailingComponents
                        delegate: Rectangle {
                            id: trailingItemCard
                            Layout.fillWidth: true
                            implicitHeight: trailingItemRow.implicitHeight + Metrics.spacingM * 2
                            radius: Metrics.cornerM
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: Appearance.colors.colOutlineVariant

                            readonly property var info: PersonalizationConfig.barComponentInfo(modelData)

                            RowLayout {
                                id: trailingItemRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: Metrics.spacingM
                                }
                                spacing: Metrics.spacingM

                                // Index badge
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: Appearance.rounding.full
                                    color: Appearance.colors.colSecondaryContainer

                                    Text {
                                        anchors.centerIn: parent
                                        text: String(index + 1)
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                }

                                // Icon
                                Rectangle {
                                    Layout.preferredWidth: 38
                                    Layout.preferredHeight: 38
                                    radius: Metrics.cornerS
                                    color: Appearance.colors.colPrimaryContainer

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: trailingItemCard.info.icon || "widgets"
                                        iconSize: 20
                                        color: Appearance.colors.colOnPrimaryContainer
                                    }
                                }

                                // Title & Description
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    spacing: 3

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Metrics.spacingS
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                            text: trailingItemCard.info.label
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnSurface
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        Rectangle {
                                            visible: trailingItemCard.info.tag.length > 0
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: Math.min(100, tagTrailingText.implicitWidth + 12)
                                            Layout.maximumWidth: 100
                                            radius: 4
                                            color: Appearance.colors.colSurfaceContainerHigh
                                            clip: true

                                            Text {
                                                id: tagTrailingText
                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    verticalCenter: parent.verticalCenter
                                                    leftMargin: 6
                                                    rightMargin: 6
                                                }
                                                horizontalAlignment: Text.AlignHCenter
                                                text: trailingItemCard.info.tag
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                                color: Appearance.colors.colOnSurfaceVariant
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: trailingItemCard.info.description
                                        font.pixelSize: 12
                                        color: Appearance.colors.colOnSurfaceVariant
                                        wrapMode: Text.Wrap
                                    }
                                }

                                // Actions
                                RowLayout {
                                    spacing: Metrics.spacingXXS

                                    IconButton {
                                        iconName: root.horizontalBar ? "arrow_back" : "arrow_upward"
                                        tooltipText: root.horizontalBar ? qsTr("Move left") : qsTr("Move up")
                                        enabled: index > 0
                                        variant: "standard"
                                        onClicked: PersonalizationConfig.moveBarComponent(modelData, "trailing", index - 1)
                                    }

                                    IconButton {
                                        iconName: root.horizontalBar ? "arrow_forward" : "arrow_downward"
                                        tooltipText: root.horizontalBar ? qsTr("Move right") : qsTr("Move down")
                                        enabled: index < PersonalizationConfig.barTrailingComponents.length - 1
                                        variant: "standard"
                                        onClicked: PersonalizationConfig.moveBarComponent(modelData, "trailing", index + 1)
                                    }

                                    IconButton {
                                        iconName: root.horizontalBar ? "swap_horiz" : "swap_vert"
                                        tooltipText: root.horizontalBar ? qsTr("Move to left zone") : qsTr("Move to top zone")
                                        variant: "tonal"
                                        onClicked: PersonalizationConfig.moveBarComponent(modelData, "leading", PersonalizationConfig.barLeadingComponents.length)
                                    }

                                    IconButton {
                                        iconName: "close"
                                        tooltipText: qsTr("Remove")
                                        variant: "standard"
                                        onClicked: PersonalizationConfig.removeBarComponent(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Empty state
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: Metrics.cornerM
                        color: Appearance.colors.colLayer2
                        visible: PersonalizationConfig.barTrailingComponents.length === 0

                        Text {
                            anchors.centerIn: parent
                            width: Math.max(0, parent.width - Metrics.spacingM * 2)
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.horizontalBar ? qsTr("No right-zone components. Select an item below to add one.") : qsTr("No bottom-zone components. Select an item below to add one.")
                            color: Appearance.colors.colOnSurfaceVariant
                            font.pixelSize: 12
                        }
                    }

                    // Available to add
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingXS
                        readonly property var available: {
                            const trailing = PersonalizationConfig.barTrailingComponents;
                            return PersonalizationConfig.barComponentIds.filter(id => trailing.indexOf(id) === -1);
                        }
                        visible: available.length > 0

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: root.horizontalBar ? qsTr("Add component to right zone:") : qsTr("Add component to bottom zone:")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        Flow {
                            Layout.fillWidth: true
                            width: parent.width
                            spacing: Metrics.spacingS

                            Repeater {
                                model: parent.parent.available
                                delegate: ActionButton {
                                    readonly property var addInfo: PersonalizationConfig.barComponentInfo(modelData)
                                    readonly property bool isInLeading: PersonalizationConfig.barLeadingComponents.indexOf(modelData) !== -1
                                    iconName: addInfo.icon || "widgets"
                                    text: isInLeading ? (root.horizontalBar ? qsTr("%1 (from left)").arg(addInfo.label) : qsTr("%1 (from top)").arg(addInfo.label)) : qsTr("+ %1").arg(addInfo.label)
                                    onClicked: PersonalizationConfig.moveBarComponent(modelData, "trailing", PersonalizationConfig.barTrailingComponents.length)
                                }
                            }
                        }
                    }
                }
            }

            // Quick Settings Drawer Widgets Section
            SettingsSection {
                Layout.fillWidth: true
                flat: false
                title: qsTr("Quick settings drawer widgets")
                iconName: "tune"
                supportingText: qsTr("Customize which widgets appear in the Quick Settings drawer and their display order.")

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Metrics.spacingS

                    RowLayout {
                        Layout.fillWidth: true
                        Item { Layout.fillWidth: true }
                        ActionButton {
                            iconName: "restart_alt"
                            text: qsTr("Reset widgets")
                            onClicked: PersonalizationConfig.resetQuickSettingsComponents()
                        }
                    }

                    Repeater {
                        model: PersonalizationConfig.quickSettingsComponentIds
                        delegate: Rectangle {
                            id: qsWidgetCard
                            Layout.fillWidth: true
                            implicitHeight: qsWidgetRow.implicitHeight + Metrics.spacingM * 2
                            radius: Metrics.cornerM
                            color: Appearance.colors.colLayer2
                            border.width: 1
                            border.color: Appearance.colors.colOutlineVariant

                            readonly property var wInfo: PersonalizationConfig.quickSettingsWidgetInfo(modelData)
                            readonly property bool isEnabled: PersonalizationConfig.quickSettingsComponents.indexOf(modelData) !== -1
                            readonly property int orderIndex: PersonalizationConfig.quickSettingsComponents.indexOf(modelData)

                            RowLayout {
                                id: qsWidgetRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: Metrics.spacingM
                                }
                                spacing: Metrics.spacingM

                                Rectangle {
                                    Layout.preferredWidth: 38
                                    Layout.preferredHeight: 38
                                    radius: Metrics.cornerS
                                    color: qsWidgetCard.isEnabled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSurfaceContainerHigh

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: qsWidgetCard.wInfo.icon || "widgets"
                                        iconSize: 20
                                        color: qsWidgetCard.isEnabled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurfaceVariant
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    spacing: 3

                                    Text {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        text: qsWidgetCard.wInfo.label
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnSurface
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsWidgetCard.wInfo.description
                                        font.pixelSize: 12
                                        color: Appearance.colors.colOnSurfaceVariant
                                        wrapMode: Text.Wrap
                                    }
                                }

                                RowLayout {
                                    spacing: Metrics.spacingXXS
                                    visible: qsWidgetCard.isEnabled

                                    IconButton {
                                        iconName: "arrow_upward"
                                        tooltipText: qsTr("Move earlier")
                                        enabled: qsWidgetCard.orderIndex > 0
                                        variant: "standard"
                                        onClicked: PersonalizationConfig.moveQuickSettingsComponent(modelData, qsWidgetCard.orderIndex - 1)
                                    }

                                    IconButton {
                                        iconName: "arrow_downward"
                                        tooltipText: qsTr("Move later")
                                        enabled: qsWidgetCard.orderIndex < PersonalizationConfig.quickSettingsComponents.length - 1
                                        variant: "standard"
                                        onClicked: PersonalizationConfig.moveQuickSettingsComponent(modelData, qsWidgetCard.orderIndex + 1)
                                    }
                                }

                                StyledSwitch {
                                    checked: qsWidgetCard.isEnabled
                                    Accessible.name: qsWidgetCard.wInfo.label
                                    onToggled: PersonalizationConfig.toggleQuickSettingsComponent(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
