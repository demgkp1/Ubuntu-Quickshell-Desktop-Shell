pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * AudioService - PipeWire Audio Subsystem Provider
 *
 * Tracks default audio sink volume, mute state, and device descriptions
 * reactively using Quickshell's native PipeWire service and PwObjectTracker.
 */
Singleton {
    id: root

    // Object tracker binds the active sink to receive volume/muted changes
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    readonly property bool isReady: Pipewire.ready
    readonly property bool hasSink: Pipewire.defaultAudioSink !== null
    readonly property string sinkName: Pipewire.defaultAudioSink?.description || Pipewire.defaultAudioSink?.name || "No Output"

    // Volume level normalized (0.0 - 1.0+, Pipewire allows boost up to 1.5)
    readonly property real volume: Pipewire.defaultAudioSink?.audio?.volume ?? 0.0
    readonly property int volumePercent: Math.round(volume * 100)

    // Muted state
    readonly property bool isMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    // Set volume level directly (0.0 to 1.5)
    function setVolume(val) {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.volume = Math.max(0.0, Math.min(1.5, val));
        }
    }

    // Adjust volume by relative step (e.g. +0.05 or -0.05)
    function stepVolume(delta) {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            var cur = Pipewire.defaultAudioSink.audio.volume;
            setVolume(cur + delta);
        }
    }

    // Toggle mute state
    function toggleMute() {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }
    }
}
