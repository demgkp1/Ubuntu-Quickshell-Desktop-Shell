import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window
import qs.Common
import qs.Services
import qs.Components
import qs.Widgets.common

StyledFlickable {
    id: root

    clip: true
    contentWidth: width
    contentHeight: contentColumn.y + contentColumn.implicitHeight + 24

    readonly property real maxContentWidth: 600
    readonly property real pageContentWidth: Math.min(root.maxContentWidth, Math.max(0, root.width - Metrics.pageMargin * 2))

    component Section: ColumnLayout {
        id: section

        property string title: ""
        property string iconName: "palette"
        property string supportingText: ""
        default property alias content: body.data

        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                text: section.iconName
                iconSize: 26
                fill: 1
                color: Appearance.colors.colOnSecondaryContainer
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: section.title
                color: Appearance.colors.colOnSecondaryContainer
                font.family: Fonts.ui
                font.pixelSize: 18
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        Text {
            Layout.fillWidth: true
            visible: section.supportingText.length > 0
            text: section.supportingText
            color: Appearance.colors.colSubtext
            font.family: Fonts.ui
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            id: body

            Layout.fillWidth: true
            spacing: 10
        }
    }

    component PreviewSegmentGroup: Item {
        id: previewGroup

        property bool selected: false
        property bool darkPreview: false
        readonly property bool matchesCurrentMode: darkPreview === Appearance.m3colors.darkmode
        readonly property color fallbackSurface: matchesCurrentMode
                                                 ? (darkPreview ? Appearance.m3colors.m3surfaceContainerHighest
                                                                : Appearance.m3colors.m3surfaceContainerLowest)
                                                 : Appearance.m3colors.m3inverseSurface
        readonly property color fallbackOnSurface: matchesCurrentMode
                                                   ? Appearance.m3colors.m3onSurface
                                                   : Appearance.m3colors.m3inverseOnSurface
        property color normalFill: Appearance.mix(fallbackSurface, fallbackOnSurface, darkPreview ? 0.72 : 0.86)
        property color selectedFill: Appearance.colors.colPrimary
        property color checkColor: Appearance.colors.colOnPrimary

        implicitWidth: 260
        implicitHeight: 34

        readonly property real gap: 3
        readonly property real segmentHeight: height
        readonly property real firstWidth: Math.round(width * 0.315)
        readonly property real middleWidth: Math.round(width * 0.34)
        readonly property real lastWidth: Math.max(0, width - firstWidth - middleWidth - gap * 2)

        Rectangle {
            x: 0
            y: 0
            width: previewGroup.firstWidth
            height: previewGroup.segmentHeight
            radius: height / 2
            color: previewGroup.selected ? previewGroup.selectedFill : previewGroup.normalFill
            opacity: previewGroup.selected ? 1 : 0.82
            antialiasing: true

            MaterialSymbol {
                anchors.centerIn: parent
                text: "check"
                iconSize: 16
                fill: 1
                color: previewGroup.checkColor
                visible: previewGroup.selected
            }
        }

        Rectangle {
            x: previewGroup.firstWidth + previewGroup.gap
            y: 0
            width: previewGroup.middleWidth
            height: previewGroup.segmentHeight
            radius: 5
            color: previewGroup.normalFill
            opacity: 0.82
            antialiasing: true
        }

        Rectangle {
            x: previewGroup.firstWidth + previewGroup.middleWidth + previewGroup.gap * 2
            y: 0
            width: previewGroup.lastWidth
            height: previewGroup.segmentHeight
            topLeftRadius: 0
            bottomLeftRadius: 0
            topRightRadius: height / 2
            bottomRightRadius: height / 2
            color: previewGroup.normalFill
            opacity: 0.82
            antialiasing: true
        }
    }

    component ThemePreviewCard: Item {
        id: themeCard

        required property string mode
        required property string title
        property bool darkPreview: false
        readonly property bool active: PersonalizationConfig.themeMode === mode
        readonly property bool hovered: cardMouse.containsMouse
        readonly property bool pressed: cardMouse.pressed
        readonly property bool matchesCurrentMode: darkPreview === Appearance.m3colors.darkmode
        readonly property color selectedAccent: Appearance.colors.colPrimary
        readonly property color selectedOnAccent: Appearance.colors.colOnPrimary
        readonly property color outerFill: active
                                         ? (pressed ? Appearance.colors.colPrimaryActive
                                                    : (hovered ? Appearance.colors.colPrimaryHover : selectedAccent))
                                         : (pressed ? Appearance.colors.colLayer1Active
                                                    : (hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1))
        readonly property color previewSurface: matchesCurrentMode
                                              ? (darkPreview ? Appearance.m3colors.m3surfaceContainerHighest
                                                             : Appearance.m3colors.m3surfaceContainerLowest)
                                              : Appearance.m3colors.m3inverseSurface
        readonly property color previewOnSurface: matchesCurrentMode
                                                ? Appearance.m3colors.m3onSurface
                                                : Appearance.m3colors.m3inverseOnSurface
        readonly property color avatarFill: Appearance.mix(previewSurface, previewOnSurface, darkPreview ? 0.52 : 0.85)
        readonly property color placeholderFill: Appearance.mix(previewSurface, previewOnSurface, darkPreview ? 0.48 : 0.84)
        readonly property color placeholderAltFill: Appearance.mix(previewSurface, previewOnSurface, darkPreview ? 0.62 : 0.80)
        readonly property color waveFill: active ? selectedAccent : Appearance.mix(previewSurface, previewOnSurface, darkPreview ? 0.52 : 0.76)
        readonly property color trackFill: Appearance.mix(previewSurface, previewOnSurface, darkPreview ? 0.66 : 0.82)
        readonly property color labelText: active ? selectedOnAccent : (hovered ? Appearance.colors.colOnSurface : Appearance.colors.colOnLayer1)

        signal clicked

        implicitWidth: 288
        implicitHeight: 180
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredWidth: 288
        Layout.preferredHeight: 180
        scale: cardMouse.pressed ? 0.985 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutSine
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 13
            color: themeCard.outerFill
            border.width: themeCard.hovered && !themeCard.active ? 1 : 0
            border.color: Appearance.colors.colOutlineVariant

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.expressiveFastEffects.duration
                    easing.type: Appearance.animation.expressiveFastEffects.type
                    easing.bezierCurve: Appearance.animation.expressiveFastEffects.bezierCurve
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 33
            bottomLeftRadius: 13
            bottomRightRadius: 13
            color: "transparent"

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 8
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: themeCard.title
                color: themeCard.labelText
                font.family: Fonts.ui
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }

        Rectangle {
            id: previewPane

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 10
            anchors.bottomMargin: 37
            radius: 8
            color: themeCard.previewSurface
            border.width: 0

            Rectangle {
                x: 15
                y: 12
                width: 46
                height: 46
                radius: width / 2
                color: themeCard.avatarFill
                opacity: themeCard.darkPreview ? 0.9 : 0.92
            }

            Column {
                x: 72
                y: 16
                spacing: 8

                Rectangle {
                    width: Math.max(24, Math.min(154, previewPane.width - 92))
                    height: 18
                    radius: 5
                    color: themeCard.placeholderFill
                    opacity: themeCard.darkPreview ? 0.85 : 1
                }

                Rectangle {
                    width: Math.max(24, Math.min(124, previewPane.width - 118))
                    height: 16
                    radius: 5
                    color: themeCard.placeholderAltFill
                    opacity: themeCard.darkPreview ? 0.95 : 1
                }
            }

            MiniMaterialWaveLine {
                x: 18
                y: 66
                width: Math.max(0, previewPane.width - 36)
                height: 18
                waveColor: themeCard.waveFill
                trackColor: themeCard.trackFill
                trackOpacity: themeCard.darkPreview ? 0.42 : 0.54
                wavePortion: 0.72
                phaseDuration: 1600
                flowing: themeCard.active
                endDotColor: themeCard.waveFill
            }

            PreviewSegmentGroup {
                x: 13
                y: previewPane.height - height - 8
                width: Math.max(0, previewPane.width - 26)
                height: 33
                selected: themeCard.active
                darkPreview: themeCard.darkPreview
                normalFill: Appearance.mix(themeCard.previewSurface, themeCard.previewOnSurface, themeCard.darkPreview ? 0.72 : 0.86)
                selectedFill: themeCard.selectedAccent
                checkColor: themeCard.selectedOnAccent
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: themeCard.clicked()
        }
    }

    component SearchSelectSettingRow: Item {
        id: selectRow

        property string title: ""
        property string description: ""
        property var options: []
        property string value: ""
        property string placeholder: ""
        property string textRole: "label"
        property string valueRole: "value"
        property int fieldWidth: 240

        signal accepted(string value)

        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(58, selectLabelColumn.implicitHeight + 16)
        opacity: enabled ? 1 : 0.45

        RowLayout {
            anchors.fill: parent
            spacing: 16

            Column {
                id: selectLabelColumn

                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: selectRow.title
                    color: Appearance.colors.colOnSurface
                    font.family: Fonts.ui
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: selectRow.description
                    color: Appearance.colors.colSubtext
                    font.family: Fonts.ui
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    visible: text !== ""
                }
            }

            SearchSelectMenuField {
                closeOnAccept: false
                Layout.preferredWidth: Math.min(selectRow.fieldWidth, Math.max(120, Math.floor((selectRow.width - 16) * 0.52)))
                Layout.maximumWidth: Math.max(0, selectRow.width)
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter
                options: selectRow.options
                value: selectRow.value
                placeholder: selectRow.placeholder
                textRole: selectRow.textRole
                valueRole: selectRow.valueRole
                onAccepted: value => selectRow.accepted(value)
            }
        }
    }

    component ToggleSettingRow: Item {
        id: toggleRow

        property string title: ""
        property string description: ""
        property bool checked: false

        signal toggled(bool checked)

        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(58, toggleLabelColumn.implicitHeight + 16)
        opacity: enabled ? 1 : 0.45

        RowLayout {
            anchors.fill: parent
            spacing: 16

            Column {
                id: toggleLabelColumn
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: toggleRow.title
                    color: Appearance.colors.colOnSurface
                    font.family: Fonts.ui
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: toggleRow.description
                    color: Appearance.colors.colSubtext
                    font.family: Fonts.ui
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    visible: text !== ""
                }
            }

            StyledSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: toggleRow.checked
                onToggled: toggleRow.toggled(checked)
            }
        }
    }

    component SliderSettingRow: ColumnLayout {
        id: sliderRow

        property string title: ""
        property string description: ""
        property real value: 0
        property real from: 0
        property real to: 1
        property real stepSize: 1
        property string suffix: ""

        signal moved(real value)

        Layout.fillWidth: true
        spacing: 6
        opacity: enabled ? 1 : 0.45

        function formatValue(displayValue) {
            return Math.round(displayValue).toString() + (suffix !== "" ? " " + suffix : "");
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                text: sliderRow.title
                color: Appearance.colors.colOnSurface
                font.family: Fonts.ui
                font.pixelSize: 15
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: sliderRow.formatValue(sliderRow.value)
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Fonts.numeric
                font.pixelSize: Typography.bodyMedium.pixelSize
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        Text {
            Layout.fillWidth: true
            text: sliderRow.description
            color: Appearance.colors.colSubtext
            font.family: Fonts.ui
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        MaterialSlider {
            id: settingSlider

            Layout.fillWidth: true
            Layout.preferredHeight: 72
            from: sliderRow.from
            to: sliderRow.to
            stepSize: sliderRow.stepSize
            value: sliderRow.value
            accessibleName: sliderRow.title
            valueFormatter: sliderValue => Math.round(sliderValue).toString() + sliderRow.suffix
            onMoved: value => sliderRow.moved(Math.round(value))
        }
    }

    ColumnLayout {
        id: contentColumn
        width: root.pageContentWidth
        x: Math.max(Metrics.pageMargin, (root.width - width) / 2)
        y: 28
        spacing: 30

        NiriSetupPrompt {
            Layout.fillWidth: true
            title: qsTr("Cursor integration")
            description: qsTr("Create or connect the Clavis cursor configuration.")
            integrationState: NiriConfigService.state("cursor")
            busy: NiriConfigService.busy && NiriConfigService.activeFeature === "cursor"
            blocked: NiriConfigService.busy
            error: NiriConfigService.error
            onSetupRequested: NiriConfigService.setup("cursor")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ThemePreviewCard {
                title: qsTr("Light")
                mode: "light"
                darkPreview: false
                onClicked: ThemeService.setThemeMode("light")
            }

            ThemePreviewCard {
                title: qsTr("Dark")
                mode: "dark"
                darkPreview: true
                onClicked: ThemeService.setThemeMode("dark")
            }
        }

        Section {
            id: searchSection0
            title: searchAnchor0.title
            SettingsSearchAnchor {
                id: searchAnchor0
                target: searchSection0
                declaration:
                    '{"id":"theme.section.matugen-color-scheme","route":"theme","title":"matugen color scheme","context":"ThemePage","icon":"palette","aliases":[]}'
            }
            iconName: "colors"

            ColumnLayout {
                id: schemeRowsColumn

                Layout.fillWidth: true
                spacing: 4

                readonly property int rowPadding: root.pageContentWidth < 520 ? 16 : 24
                readonly property var schemeRows: root.pageContentWidth < 460
                    ? [
                          PersonalizationConfig.matugenSchemes.slice(0, 3),
                          PersonalizationConfig.matugenSchemes.slice(3, 6),
                          PersonalizationConfig.matugenSchemes.slice(6, 9)
                      ]
                    : [
                          PersonalizationConfig.matugenSchemes.slice(0, 5),
                          PersonalizationConfig.matugenSchemes.slice(5, 9)
                      ]

                Repeater {
                    model: schemeRowsColumn.schemeRows

                    delegate: Flickable {
                        id: schemeRowFlickable

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: schemeGroup.implicitHeight
                        contentWidth: schemeGroup.implicitWidth
                        contentHeight: schemeGroup.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick
                        interactive: contentWidth > width
                        clip: true

                        StyledButtonGroup {
                            id: schemeGroup

                            model: schemeRowFlickable.modelData
                            currentValue: PersonalizationConfig.matugenScheme
                            horizontalPadding: schemeRowsColumn.rowPadding
                            onValueSelected: value => ThemeService.setMatugenScheme(value)
                        }
                    }
                }
            }
        }

        Section {
            id: searchSection1
            title: searchAnchor1.title
            SettingsSearchAnchor {
                id: searchAnchor1
                target: searchSection1
                declaration:
                    '{"id":"theme.section.super-key-appearance","route":"theme","title":"Super key appearance","context":"ThemePage","icon":"palette","aliases":[]}'
            }
            iconName: "keyboard"
            Flow {
                Layout.fillWidth: true
                spacing: Metrics.spacingS
                Repeater {
                    model: PersonalizationConfig.superKeyStyles
                    delegate: RippleButton {
                        id: superChoice
                        required property var modelData
                        implicitWidth: 84
                        implicitHeight: 56
                        pointingHandCursor: true
                        toggled: PersonalizationConfig.superKeyStyle === modelData.value
                        selectedStateLayerEnabled: true
                        buttonRadius: Appearance.rounding.small
                        containerColor: PersonalizationConfig.superKeyStyle === modelData.value
                                        ? Appearance.colors.colSecondaryContainer :
                                          Appearance.colors.colLayer2
                        hoverStateLayerOpacity: Appearance.interaction.hoverStateLayerOpacity
                        pressedStateLayerOpacity: Appearance.interaction.pressedStateLayerOpacity
                        focusStateLayerOpacity: Appearance.interaction.focusStateLayerOpacity
                        selectedStateLayerOpacity: Appearance.interaction.selectedStateLayerOpacity
                        Accessible.name: modelData.label
                        Accessible.role: Accessible.RadioButton
                        Accessible.checked: PersonalizationConfig.superKeyStyle === modelData.value
                        onClicked: PersonalizationConfig.setValue("superKeyStyle", modelData.value)
                        contentItem: Item {
                            ShortcutKeycap {
                                anchors.centerIn: parent
                                keyText: "Super"
                                superStyle: superChoice.modelData.value
                            }
                        }
                        StyledToolTip {
                            text: parent.modelData.label
                            visible: parent.hovered
                        }
                    }
                }
            }
        }

        Section {
            id: searchSection2
            title: searchAnchor2.title
            SettingsSearchAnchor {
                id: searchAnchor2
                target: searchSection2
                declaration:
                    '{"id":"theme.section.lock-screen","route":"theme","title":"Lock screen","context":"ThemePage","icon":"palette","aliases":[]}'
            }
            iconName: "lock"

            InlineStatusBanner {
                Layout.fillWidth: true
                tone: "info"
                message: !ThemeService.isNiriSession
                         ? qsTr("Unavailable on GNOME; lock screen appearance is managed by GNOME Shell.")
                         : qsTr("Lock screen style selection is managed by the active desktop session.")
            }

            SearchSelectMenuField {
                closeOnAccept: true
                Layout.fillWidth: true
                Layout.maximumWidth: 240
                Layout.preferredHeight: 40
                enabled: false
                opacity: enabled ? 1 : 0.45
                options: [{value: "gnome", label: qsTr("GNOME secure lock screen")}]
                value: "gnome"
                textRole: "label"
                valueRole: "value"
                onAccepted: value => PersonalizationConfig.setLockScreenStyle(value)
            }
        }

        Section {
            id: searchSection3
            title: searchAnchor3.title
            SettingsSearchAnchor {
                id: searchAnchor3
                target: searchSection3
                declaration:
                    '{"id":"theme.section.cursor-theme","route":"theme","title":"Cursor theme","context":"ThemePage","icon":"palette","aliases":[]}'
            }
            iconName: "mouse"

            InlineStatusBanner {
                Layout.fillWidth: true
                visible: !ThemeService.isNiriSession
                tone: "info"
                message: qsTr("Unavailable on GNOME; cursor theme, size, and inactivity hiding are managed by GNOME Settings.")
            }

            CursorThemeSelect {
                enabled: NiriConfigService.ready("cursor")
                opacity: enabled ? 1 : 0.45
                fieldWidth: Math.min(240, Math.max(120, Math.floor((root.pageContentWidth - 16) * 0.52)))
                cursorThemes: ThemeService.availableCursorThemes
                currentCursorTheme: PersonalizationConfig.cursorTheme
                onAccepted: value => ThemeService.setCursorTheme(value)
            }

            InlineStatusBanner {
                Layout.fillWidth: true
                visible: ThemeService.cursorLastError !== ""
                tone: "error"
                message: ThemeService.cursorLastError
            }

            SliderSettingRow {
                enabled: NiriConfigService.ready("cursor")
                title: qsTr("Cursor size")
                from: 12
                to: 128
                stepSize: 1
                suffix: qsTr("pixels")
                value: PersonalizationConfig.cursorSize
                onMoved: value => ThemeService.setCursorSize(Math.round(value))
            }

            ToggleSettingRow {
                enabled: NiriConfigService.ready("cursor")
                title: qsTr("Hide while typing")
                checked: PersonalizationConfig.cursorHideWhenTyping
                onToggled: checked => ThemeService.setCursorHideWhenTyping(checked)
            }

            SliderSettingRow {
                enabled: NiriConfigService.ready("cursor")
                title: qsTr("Hide after timeout")
                description: qsTr("Hide the cursor after inactivity; 0 disables this")
                from: 0
                to: 5000
                stepSize: 100
                suffix: qsTr("milliseconds")
                value: PersonalizationConfig.cursorHideAfterInactiveMs
                onMoved: value => ThemeService.setCursorHideAfterInactiveMs(Math.round(value))
            }
        }

        Section {
            id: searchSection4
            title: searchAnchor4.title
            SettingsSearchAnchor {
                id: searchAnchor4
                target: searchSection4
                declaration:
                    '{"id":"theme.section.icon-theme","route":"theme","title":"Icon theme","context":"ThemePage","icon":"palette","aliases":[]}'
            }
            iconName: "interests"

            SearchSelectSettingRow {
                title: qsTr("Icon theme")
                options: ThemeService.availableIconThemes
                value: PersonalizationConfig.iconTheme
                placeholder: qsTr("Choose icon theme")
                onAccepted: value => ThemeService.setIconTheme(value)
            }
        }

        Section {
            id: searchSection5
            title: searchAnchor5.title
            SettingsSearchAnchor {
                id: searchAnchor5
                target: searchSection5
                declaration:
                    '{"id":"theme.section.fonts","route":"theme","title":"Fonts","context":"ThemePage","icon":"palette","aliases":[]}'
            }
            iconName: "text_format"

            SearchSelectSettingRow {
                title: qsTr("UI font")
                description: qsTr("Regular headings, body text, and controls")
                options: FontService.fontOptions
                value: PersonalizationConfig.uiFontFamily
                placeholder: qsTr("Select UI font")
                fieldWidth: 280
                onAccepted: value => PersonalizationConfig.setFontFamily("ui", value)
            }

            SearchSelectSettingRow {
                title: qsTr("Monospace font")
                description: qsTr("Commands, paths, and technical information")
                options: FontService.fontOptions
                value: PersonalizationConfig.monoFontFamily
                placeholder: qsTr("Select monospace font")
                fieldWidth: 280
                onAccepted: value => PersonalizationConfig.setFontFamily("mono", value)
            }

            SearchSelectSettingRow {
                title: qsTr("Numeric font")
                description: qsTr("Time, percentages, and system values")
                options: FontService.fontOptions
                value: PersonalizationConfig.numericFontFamily
                placeholder: qsTr("Select numeric font")
                fieldWidth: 280
                onAccepted: value => PersonalizationConfig.setFontFamily("numeric", value)
            }

            SearchSelectSettingRow {
                title: qsTr("Expressive font")
                description: qsTr("Expressive visual components such as weather")
                options: FontService.fontOptions
                value: PersonalizationConfig.expressiveFontFamily
                placeholder: qsTr("Select expressive font")
                fieldWidth: 280
                onAccepted: value => PersonalizationConfig.setFontFamily("expressive", value)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
        }
    }
}
