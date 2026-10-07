import QtQuick
import Quickshell
import Quickshell.Services.Pam
import qs.Common
import qs.Services

Scope {
    id: root

    readonly property bool active: sessionLock.locked || capturePending
    readonly property bool secure: sessionLock.secure
    property bool capturePending: false
    property int activeCaptureRequestId: 0
    property string sessionStyle: "default"

    Binding {
        target: WindowPreviewService
        property: "suspended"
        value: root.active
    }

    signal unlocked
    signal secured

    function open() {
        if (sessionLock.locked || capturePending)
            return "ALREADY_LOCKED";

        sessionStyle = PersonalizationConfig.lockScreenStyle;
        internalContext.authRevealed = false;
        internalContext.currentText = "";
        internalContext.unlockInProgress = false;
        internalContext.showFailure = false;
        capturePending = true;
        activeCaptureRequestId = preLockCapture.capture();
        return "LOCKED";
    }

    function isLocked() {
        return sessionLock.locked || capturePending;
    }

    function close() {
        return unlock();
    }

    function unlock() {
        internalContext.finishUnlock();
        return "UNLOCKED";
    }

    function finishCapture(captureRequestId) {
        if (!capturePending || captureRequestId !== activeCaptureRequestId)
            return;

        sessionLock.locked = true;
        capturePending = false;
        root.secured();
    }

    onActiveChanged: {
        SystemIdentityService.setUptimeConsumer("lock-screen", root.active);
        SystemMonitorService.setConsumerModules("lock-screen", root.active ? ["cpu", "memory", "disk"] : []);
    }
    Component.onDestruction: {
        preLockCapture.cancel();
        preLockCapture.clear();
        SystemIdentityService.setUptimeConsumer("lock-screen", false);
        SystemMonitorService.clearConsumer("lock-screen");
    }

    PreLockCapture {
        id: preLockCapture

        onCompleted: captureRequestId => {
            return root.finishCapture(captureRequestId);
        }
    }

    Scope {
        id: internalContext

        property bool authRevealed: false
        property string currentText: ""
        property bool unlockInProgress: false
        property bool showFailure: false

        signal unlockFailed

        function tryUnlock() {
            if (currentText === "" || unlockInProgress)
                return;

            internalContext.unlockInProgress = true;
            pam.start();
        }

        function finishUnlock() {
            if (!sessionLock.locked)
                return;
            sessionLock.locked = false;
            root.unlocked();
            Qt.callLater(preLockCapture.clear);
        }

        PamContext {
            id: pam

            configDirectory: Paths.shellDir + "/Modules/Lock/pam"
            config: "password.conf"
            onPamMessage: {
                if (this.responseRequired)
                    this.respond(internalContext.currentText);
            }
            onCompleted: result => {
                if (result == PamResult.Success) {
                    internalContext.currentText = "";
                    internalContext.showFailure = false;
                    sessionLock.unlock();
                } else {
                    internalContext.currentText = "";
                    internalContext.showFailure = true;
                    internalContext.unlockFailed();
                }
                internalContext.unlockInProgress = false;
            }
        }
    }

    QtObject {
        id: sessionLock

        property bool locked: false
        readonly property bool secure: true

        function unlock() {
            internalContext.finishUnlock();
        }

        onLockedChanged: {
            if (!locked)
                root.unlocked();
        }
    }

    Variants {
        model: Quickshell.screens

        LockWindow {
            required property var modelData
            targetScreen: modelData
            lockContext: internalContext
            lockController: sessionLock
            snapshotProvider: preLockCapture
            sessionStyle: root.sessionStyle
        }
    }
}
