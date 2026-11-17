import QtQuick
import Clavis.Cava as Native
Native.AudioLevelProvider {
    readonly property real level: rms
    readonly property var values: [rms, peak]
}
