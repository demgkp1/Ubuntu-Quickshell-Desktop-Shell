cmake_minimum_required(VERSION 3.21)
project(ClavisGnome VERSION 0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick Network Concurrent OpenGL)
find_package(PkgConfig REQUIRED)
pkg_check_modules(Pipewire REQUIRED IMPORTED_TARGET libpipewire-0.3)
pkg_search_module(Cava REQUIRED IMPORTED_TARGET cava libcava)
pkg_check_modules(Xcb REQUIRED IMPORTED_TARGET xcb xcb-randr)
qt_standard_project_setup(REQUIRES 6.8)
set(CLAVIS_QML_BUILD_DIR "${CMAKE_BINARY_DIR}/qml")
add_executable(ClavisGraphicsProbe native/runtime/graphics_probe.cpp)
target_link_libraries(ClavisGraphicsProbe PRIVATE Qt6::Gui Qt6::OpenGL)
set_target_properties(ClavisGraphicsProbe PROPERTIES
    OUTPUT_NAME clavis-graphics-probe
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
qt_add_library(ClavisCava SHARED)
qt_add_qml_module(ClavisCava URI Clavis.Cava
    OUTPUT_DIRECTORY "${CLAVIS_QML_BUILD_DIR}/Clavis/Cava"
    SOURCES native/audio/cava_provider.h native/audio/cava_provider.cpp
            native/audio/audio_level_provider.h native/audio/audio_level_provider.cpp
            native/audio/audio_collector.h native/audio/audio_collector.cpp
            native/audio/audio_level_collector.h native/audio/audio_level_collector.cpp
            native/audio/audio_visual_analyzer.h native/audio/audio_visual_analyzer.cpp)
target_include_directories(ClavisCava PRIVATE native/audio)
target_link_libraries(ClavisCava PRIVATE Qt6::Core Qt6::Gui Qt6::Qml PkgConfig::Pipewire PkgConfig::Cava)
set_target_properties(ClavisCava PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CLAVIS_QML_BUILD_DIR}/Clavis/Cava")
qt_add_library(ClavisMedia SHARED)
qt_add_qml_module(ClavisMedia URI Clavis.Media
    OUTPUT_DIRECTORY "${CLAVIS_QML_BUILD_DIR}/Clavis/Media"
    SOURCES native/media/media_palette_plugin.h native/media/media_palette_plugin.cpp
            native/media/media_palette_backend.h native/media/media_palette_backend.cpp)
target_include_directories(ClavisMedia PRIVATE native/media)
target_link_libraries(ClavisMedia PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Network Qt6::Concurrent)
set_target_properties(ClavisMedia PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CLAVIS_QML_BUILD_DIR}/Clavis/Media")
qt_add_library(ClavisRuntime SHARED)
qt_add_qml_module(ClavisRuntime URI Clavis.Runtime
    OUTPUT_DIRECTORY "${CLAVIS_QML_BUILD_DIR}/Clavis/Runtime"
    SOURCES native/runtime/icon_theme_controller.h native/runtime/icon_theme_controller.cpp
            native/runtime/window_decoration.h native/runtime/window_decoration.cpp
            native/runtime/panel_reservation.h native/runtime/panel_reservation.cpp)
target_include_directories(ClavisRuntime PRIVATE native/runtime)
target_link_libraries(ClavisRuntime PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Concurrent PkgConfig::Xcb)
set_target_properties(ClavisRuntime PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CLAVIS_QML_BUILD_DIR}/Clavis/Runtime")
qt_add_library(ClavisNiriCore STATIC)
target_sources(ClavisNiriCore PRIVATE
    native/niri/niri_types.h
    native/niri/niri_icon_lookup.h native/niri/niri_icon_lookup.cpp
    native/niri/niri_ipc_client.h native/niri/niri_ipc_client.cpp
    native/niri/niri_workspace_deriver.h native/niri/niri_workspace_deriver.cpp
    native/niri/niri_workspace_model.h native/niri/niri_workspace_model.cpp
    native/niri/niri_window_model.h native/niri/niri_window_model.cpp
    native/niri/niri_output_model.h native/niri/niri_output_model.cpp)
set_target_properties(ClavisNiriCore PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(ClavisNiriCore PUBLIC native/niri)
target_link_libraries(ClavisNiriCore PRIVATE Qt6::Core Qt6::Network)
qt_add_library(ClavisNiri SHARED)
qt_add_qml_module(ClavisNiri URI Clavis.Niri
    OUTPUT_DIRECTORY "${CLAVIS_QML_BUILD_DIR}/Clavis/Niri"
    SOURCES native/niri/niri_plugin.h native/niri/niri_plugin.cpp
            native/niri/niri_floating_parallax.h native/niri/niri_floating_parallax.cpp
            native/niri/niri_animation_targets.h native/niri/niri_animation_targets.cpp)
target_include_directories(ClavisNiri PRIVATE native/niri)
target_link_libraries(ClavisNiri PRIVATE ClavisNiriCore Qt6::Core Qt6::Gui Qt6::Qml Qt6::Network)
set_target_properties(ClavisNiri PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CLAVIS_QML_BUILD_DIR}/Clavis/Niri")
add_executable(ClavisPlacementProbe tests/native/placement_probe.cpp)
target_include_directories(ClavisPlacementProbe PRIVATE native/runtime)
target_link_libraries(ClavisPlacementProbe PRIVATE ClavisRuntime Qt6::Gui Qt6::Quick)
set_target_properties(ClavisPlacementProbe PROPERTIES OUTPUT_NAME clavis-placement-probe
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
