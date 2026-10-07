pragma Singleton
import QtQuick

QtObject {
    id: root

    property int pendingCount: 0

    signal analysisReady(string requestKey, int generation, var result)

    function release(requestKey) {
        // no-op
    }

    function request(requestKey, generation, sourcePath, canvasWidth, canvasHeight, fillMode, imageWidth, imageHeight) {
        Qt.callLater(() => {
            const result = {
                valid: true,
                analysisWidth: Math.max(1, Math.round(canvasWidth || 1920)),
                analysisHeight: Math.max(1, Math.round(canvasHeight || 1080)),
                canvasWidth: Number(canvasWidth || 1920),
                canvasHeight: Number(canvasHeight || 1080),
                minBusyScore: 0.0,
                maxBusyScore: 1.0,
                errorString: "",
                busyScore: function(x, y, width, height) {
                    return 0.1;
                }
            };
            root.analysisReady(String(requestKey), Number(generation), result);
        });
    }
}
