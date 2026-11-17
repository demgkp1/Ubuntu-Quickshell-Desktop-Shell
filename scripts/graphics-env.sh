#!/usr/bin/env bash
# Source inside the pinned dev shell. Never source into the user's login shell.
if [[ -z "${CLAVIS_GRAPHICS_LIBRARY_PATH:-}" || -z "${CLAVIS_GL_DRIVERS_PATH:-}" || -z "${CLAVIS_EGL_VENDOR_LIBRARY_FILENAMES:-}" ]]; then
    echo "Pinned graphics environment missing. Use scripts/launch.sh (or nix develop)." >&2
    return 1
fi
if [[ ! -d "$CLAVIS_GL_DRIVERS_PATH" || ! -r "$CLAVIS_EGL_VENDOR_LIBRARY_FILENAMES" ]]; then
    echo "Pinned Mesa drivers missing; repair/build the Nix environment first." >&2
    return 1
fi
# Do not add /usr/lib or inherit a foreign Qt/GL library search path. Every
# driver and Qt module stays in the flake's ABI-consistent Nix closure.
export LD_LIBRARY_PATH="$CLAVIS_GRAPHICS_LIBRARY_PATH"
export LIBGL_DRIVERS_PATH="$CLAVIS_GL_DRIVERS_PATH"
export __EGL_VENDOR_LIBRARY_FILENAMES="$CLAVIS_EGL_VENDOR_LIBRARY_FILENAMES"
# Mutter does not provide layer-shell. xcb/EGL renders on XWayland without
# switching the GNOME session or depending on GLX's vendor discovery.
case "${CLAVIS_XCB_GL_INTEGRATION:-xcb_egl}" in
    xcb_egl|xcb_glx) export QT_XCB_GL_INTEGRATION="${CLAVIS_XCB_GL_INTEGRATION:-xcb_egl}" ;;
    *) echo "CLAVIS_XCB_GL_INTEGRATION must be xcb_egl or xcb_glx." >&2; return 1 ;;
esac
