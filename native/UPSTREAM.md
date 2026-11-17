Audio and media palette sources adapted from StatIndet/quickshell commit 91cdecbe08831acdcff44d350e09232efe7164ed (GPL-3.0, see project LICENSE). These are project-owned build inputs; reference/ and external native trial directories are not runtime or build dependencies. M3Shapes remains an external, pinned Nix dependency.

Local changes: availability follows fresh PipeWire samples rather than FFT initialization; upstream widgets and geometry are retained.

Media palette extraction is asynchronous; local/HTTP(S) images are decoded in a worker, downloads have a 3s timeout and 8 MiB limit, stale results are discarded.

IconThemeController is copied unchanged from the same upstream commit. It changes process-local QIcon state, never GNOME GSettings.

WindowDecoration is local code: it sets frameless flags only on a QQuickItem-owned window in the current process.
