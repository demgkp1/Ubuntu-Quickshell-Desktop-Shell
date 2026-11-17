// Read-only host topology check. Native windows are created but NEVER mapped;
// no struts, settings writes, compositor actions, focus or screenshot requests.
#include "panel_reservation.h"
#include <QEventLoop>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQuickWindow>
#include <QTimer>
#include <cstdio>

int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    QJsonArray screens;
    for (auto *screen : app.screens()) {
        QQuickWindow window;
        window.setScreen(screen);
        window.setGeometry(QRect(screen->geometry().topLeft(), QSize(8, 8)));
        window.create();
        PanelReservation observer;
        QEventLoop ready;
        QTimer deadline;
        deadline.setSingleShot(true);
        QObject::connect(&deadline, &QTimer::timeout, &ready, &QEventLoop::quit);
        QObject::connect(&observer, &PanelReservation::observedChanged, &ready, [&] {
            if (observer.observed().value("state").toString() != "Pending") ready.quit();
        });
        observer.setTarget(window.contentItem());
        deadline.start(3500);
        ready.exec();
        const auto actual = observer.inspect();
        if (actual.value("state").toString() != "Ready" || !actual.value("available").toBool()
            || actual.value("visible").toBool() || !actual.value("strut").toList().isEmpty()) {
            std::fprintf(stderr, "Read-only native topology query failed or mapped/reserved a window.\n");
            return 2;
        }
        screens.append(QJsonObject::fromVariantMap(actual));
    }
    if (screens.isEmpty()) return 3;
    std::puts(QJsonDocument(screens).toJson(QJsonDocument::Compact).constData());
    return 0;
}
