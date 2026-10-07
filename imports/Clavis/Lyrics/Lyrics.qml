pragma Singleton

import QtQuick

QtObject {
    id: root

    property var lyrics: []
    property bool hasSynchronizedLyrics: false
    property string status: "idle"
    property string error: ""
    property bool loading: false
    readonly property bool hasLyrics: Array.isArray(lyrics) && lyrics.length > 0

    property string currentArtist: ""
    property string currentTitle: ""
    property string currentAlbum: ""
    property real currentLength: 0
    property string currentPlayerIdentity: ""

    signal lyricsLoaded()
    signal trackChanged()

    function clearTrack() {
        root.currentArtist = "";
        root.currentTitle = "";
        root.currentAlbum = "";
        root.currentLength = 0;
        root.currentPlayerIdentity = "";
        root.lyrics = [];
        root.hasSynchronizedLyrics = false;
        root.status = "idle";
        root.error = "";
        root.loading = false;
        root.trackChanged();
    }

    function setTrack(artist, title, album, length, playerIdentity) {
        root.currentArtist = String(artist || "");
        root.currentTitle = String(title || "");
        root.currentAlbum = String(album || "");
        root.currentLength = Number(length) || 0;
        root.currentPlayerIdentity = String(playerIdentity || "");

        if (!root.currentTitle.trim()) {
            root.clearTrack();
            return;
        }

        root.status = "empty";
        root.error = "";
        root.loading = false;
        root.lyrics = [];
        root.hasSynchronizedLyrics = false;
        root.trackChanged();
    }

    function indexForTime(timeSeconds) {
        if (!root.hasSynchronizedLyrics || !Array.isArray(root.lyrics) || root.lyrics.length === 0)
            return -1;

        const time = Number(timeSeconds) || 0;
        let activeIndex = -1;
        for (let i = 0; i < root.lyrics.length; ++i) {
            const line = root.lyrics[i];
            if (line && typeof line.time === "number" && line.time <= time) {
                activeIndex = i;
            } else if (line && typeof line.time === "number" && line.time > time) {
                break;
            }
        }
        return activeIndex;
    }
}
