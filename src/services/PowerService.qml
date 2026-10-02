pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

/**
 * PowerService - System Battery & Power Supply Provider
 *
 * Automatically detects whether the host is a laptop with battery
 * or a desktop connected directly to AC mains power.
 * Zero-polling; entirely event-driven via UPower DBus signals.
 */
Singleton {
    id: root

    // Returns whether any battery device is detected
    readonly property bool hasBattery: {
        if (UPower.displayDevice && UPower.displayDevice.isPresent && UPower.displayDevice.type === UPowerDeviceType.Battery) {
            return true;
        }
        var list = UPower.devices ? UPower.devices.values : [];
        for (var i = 0; i < list.length; i++) {
            if (list[i].type === UPowerDeviceType.Battery && list[i].isPresent) {
                return true;
            }
        }
        return false;
    }

    // Battery charge percentage (0 - 100)
    readonly property real percentage: {
        if (!hasBattery || !UPower.displayDevice) return 100.0;
        return UPower.displayDevice.percentage;
    }

    readonly property int percentInt: Math.round(percentage)

    // Charging states
    readonly property bool isCharging: {
        if (!hasBattery || !UPower.displayDevice) return false;
        var s = UPower.displayDevice.state;
        return s === UPowerDeviceState.Charging || s === UPowerDeviceState.PendingCharge;
    }

    readonly property bool isFull: {
        if (!hasBattery || !UPower.displayDevice) return false;
        return UPower.displayDevice.state === UPowerDeviceState.FullyCharged;
    }

    readonly property bool onBattery: UPower.onBattery

    // Human-readable status label
    readonly property string statusText: {
        if (!hasBattery) return "AC Power";
        if (isCharging) return "Charging " + percentInt + "%";
        if (isFull) return "Fully Charged";
        return percentInt + "%";
    }
}
