import QtQuick
import "../theme"
import "../services"

/**
 * ClockPill - Real-time Clock and Date Indicator
 *
 * Built upon the foundational Pill component. Displays synchronized
 * time and date from TimeService, formatted with Theme tokens.
 */
Pill {
    id: root

    property bool showDate: true
    property bool showSeconds: false

    Text {
        id: dateLabel
        visible: root.showDate
        text: TimeService.formattedDate
        color: root.isHovered ? Theme.colors.text : Theme.colors.textSecondary
        font.family: Theme.typography.familySans
        font.pixelSize: Theme.typography.sizeBodySmall
        font.weight: Theme.typography.weightNormal
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color {
            ColorAnimation {
                duration: Theme.animations.fast
                easing.type: Theme.animations.easeOut
            }
        }
    }

    Rectangle {
        id: separatorDot
        visible: root.showDate
        width: 3
        height: 3
        radius: 1.5
        color: Theme.colors.textMuted
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: timeLabel
        text: root.showSeconds 
              ? TimeService.formattedTime + ":" + TimeService.formattedSeconds 
              : TimeService.formattedTime
        color: Theme.colors.text
        font.family: Theme.typography.familySans
        font.pixelSize: Theme.typography.sizeBody
        font.weight: Theme.typography.weightMedium
        anchors.verticalCenter: parent.verticalCenter
    }
}
