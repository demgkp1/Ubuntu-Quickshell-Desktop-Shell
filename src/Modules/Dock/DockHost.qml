import QtQuick
import Quickshell
import qs.Services

Item {
    id: root

    function placementSnapshots() {
        const result = [];
        for (const variants of [bottomSurfaces, leftSurfaces, rightSurfaces]) {
            for (let index = 0; index < variants.instances.length; ++index)
                result.push(variants.instances[index].placementSnapshot());
        }
        return result;
    }

    // Recreate the layer surface when its anchoring topology changes.
    Variants {
        id: bottomSurfaces
        model: DockService.enabled && DockService.position === "bottom" ? Quickshell.screens : []
        DockSurface {
            required property var modelData
            screen: modelData
            edge: "bottom"
        }
    }
    Variants {
        id: leftSurfaces
        model: DockService.enabled && DockService.position === "left" ? Quickshell.screens : []
        DockSurface {
            required property var modelData
            screen: modelData
            edge: "left"
        }
    }
    Variants {
        id: rightSurfaces
        model: DockService.enabled && DockService.position === "right" ? Quickshell.screens : []
        DockSurface {
            required property var modelData
            screen: modelData
            edge: "right"
        }
    }
}
