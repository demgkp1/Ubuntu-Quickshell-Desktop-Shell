// Real, invisible GPU preflight. An existing GNOME XWayland display is used;
// no panel, settings write, compositor replacement or synthetic renderer.
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QOffscreenSurface>
#include <QOpenGLContext>
#include <QOpenGLFramebufferObject>
#include <QOpenGLFunctions>
#include <QScreen>

#include <array>
#include <cmath>
#include <cstdio>

int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    QOpenGLContext context;
    if (!context.create()) {
        std::fprintf(stderr, "Cannot create the pinned Qt OpenGL context.\n");
        return 2;
    }
    QOffscreenSurface surface;
    surface.setFormat(context.format());
    surface.create();
    if (!surface.isValid() || !context.makeCurrent(&surface)) {
        std::fprintf(stderr, "Cannot bind the offscreen surface on this display.\n");
        return 3;
    }
    auto *gl = context.functions();
    QJsonObject report;
    {
        // Read back a real FBO, rather than accepting context creation or a
        // live process as proof that rendering works.
        QOpenGLFramebufferObject framebuffer(QSize(2, 2));
        if (!framebuffer.isValid() || !framebuffer.bind()) {
            std::fprintf(stderr, "Cannot allocate the GPU test framebuffer.\n");
            return 4;
        }
        gl->glViewport(0, 0, 2, 2);
        gl->glClearColor(0.25f, 0.5f, 0.75f, 1.0f);
        gl->glClear(GL_COLOR_BUFFER_BIT);
        std::array<unsigned char, 4> pixel{};
        gl->glReadPixels(0, 0, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixel.data());
        constexpr std::array<int, 4> expected{64, 128, 191, 255};
        for (size_t i = 0; i < pixel.size(); ++i) {
            if (std::abs(int(pixel[i]) - expected[i]) > 2) {
                std::fprintf(stderr, "GPU framebuffer readback did not match the rendered color.\n");
                return 5;
            }
        }
        if (gl->glGetError() != GL_NO_ERROR) {
            std::fprintf(stderr, "OpenGL reported an error during framebuffer validation.\n");
            return 6;
        }
        const auto string = [gl](GLenum name) {
            const auto *value = gl->glGetString(name);
            return value ? QString::fromLatin1(reinterpret_cast<const char *>(value)) : QString();
        };
        QJsonArray screens;
        for (auto *screen : app.screens()) {
            const auto rect = screen->geometry();
            screens.append(QJsonObject{{"name", screen->name()},
                {"width", rect.width()}, {"height", rect.height()},
                {"dpr", screen->devicePixelRatio()}});
        }
        report = {{"platform", app.platformName()}, {"qt", qVersion()},
            {"vendor", string(GL_VENDOR)}, {"renderer", string(GL_RENDERER)},
            {"version", string(GL_VERSION)}, {"pixel", QJsonArray{pixel[0], pixel[1], pixel[2], pixel[3]}},
            {"screens", screens}};
        framebuffer.release();
    }
    context.doneCurrent();
    const auto json = QJsonDocument(report).toJson(QJsonDocument::Compact);
    std::puts(json.constData());
    return 0;
}
