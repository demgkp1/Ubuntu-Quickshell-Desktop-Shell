#include "panel_reservation.h"
#include <QDateTime>
#include <QElapsedTimer>
#include <QEvent>
#include <QFutureWatcher>
#include <QGuiApplication>
#include <QTimer>
#include <QtConcurrent/QtConcurrentRun>
#include <QtGui/qguiapplication_platform.h>
#include <xcb/randr.h>
#include <xcb/xcb.h>
#include <xcb/xcbext.h>
#include <poll.h>
#include <algorithm>
#include <array>
#include <cerrno>
#include <cmath>
#include <cstdlib>
#include <memory>
#include <utility>
#include <vector>

struct PanelNativeState {
    bool available = false;
    quint32 window = 0;
    quint32 root = 0;
    quint32 strutAtom = 0;
    quint32 partialAtom = 0;
    QRect windowRect;
    QRect monitorRect;
    QRect rootRect;
    std::vector<quint32> strut;
    std::vector<quint32> partial;
    std::vector<quint32> frameExtents;
    QString error;
    qint64 readbackAt = 0;
};

namespace {
template<typename T> using Reply = std::unique_ptr<T, decltype(&std::free)>;
xcb_connection_t *connection() {
    auto *x11 = qGuiApp ? qGuiApp->nativeInterface<QNativeInterface::QX11Application>() : nullptr;
    return x11 ? x11->connection() : nullptr;
}
QVariantMap rectMap(const QRectF &rect) {
    return {{"x", rect.x()}, {"y", rect.y()}, {"width", rect.width()}, {"height", rect.height()}};
}

// This connection belongs exclusively to a read-only worker. Never wait for
// a server reply on Qt's GUI connection or touch QWindow/QScreen off-thread.
// The deadline covers the whole query, not 3 seconds per individual request.
class NativeQuery {
public:
    explicit NativeQuery(const QByteArray &display) {
        elapsed.start();
        conn = xcb_connect(display.constData(), nullptr);
        if (!conn || xcb_connection_has_error(conn)) error = "X11 connection unavailable";
    }
    ~NativeQuery() { if (conn) xcb_disconnect(conn); }
    template<typename T, typename Cookie> Reply<T> reply(Cookie cookie) {
        if (!error.isEmpty()) return {nullptr, &std::free};
        if (elapsed.elapsed() >= 3000) {
            error = "Native placement readback deadline exceeded";
            xcb_discard_reply(conn, cookie.sequence);
            return {nullptr, &std::free};
        }
        xcb_flush(conn);
        while (!xcb_connection_has_error(conn)) {
            void *data = nullptr;
            xcb_generic_error_t *failure = nullptr;
            if (xcb_poll_for_reply(conn, cookie.sequence, &data, &failure)) {
                if (failure) error = QString("X11 request failed (%1)").arg(failure->error_code);
                std::free(failure);
                return {static_cast<T *>(data), &std::free};
            }
            const auto remaining = 3000 - elapsed.elapsed();
            if (remaining <= 0) {
                error = "Native placement readback deadline exceeded";
                xcb_discard_reply(conn, cookie.sequence);
                return {nullptr, &std::free};
            }
            pollfd socket{xcb_get_file_descriptor(conn), POLLIN, 0};
            const auto ready = ::poll(&socket, 1, int(remaining));
            if (ready < 0 && errno == EINTR) continue;
            if (ready < 0 || (socket.revents & (POLLERR | POLLHUP | POLLNVAL))) break;
        }
        error = "X11 connection lost during placement readback";
        return {nullptr, &std::free};
    }
    quint32 atom(const char *name) {
        const QByteArray bytes(name);
        const auto value = reply<xcb_intern_atom_reply_t>(xcb_intern_atom(conn, 0, bytes.size(), bytes.data()));
        return value ? value->atom : XCB_ATOM_NONE;
    }
    std::vector<quint32> property(quint32 window, quint32 name) {
        const auto value = reply<xcb_get_property_reply_t>(xcb_get_property(conn, 0, window, name, XCB_ATOM_CARDINAL, 0, 12));
        if (!value || value->format != 32 || value->type != XCB_ATOM_CARDINAL
            || xcb_get_property_value_length(value.get()) <= 0) return {};
        auto *values = static_cast<quint32 *>(xcb_get_property_value(value.get()));
        return {values, values + xcb_get_property_value_length(value.get()) / 4};
    }
    xcb_connection_t *conn = nullptr;
    QString error;
private:
    QElapsedTimer elapsed;
};

PanelNativeState queryNative(const QByteArray &display, quint32 window, const QByteArray &screenName) {
    PanelNativeState result;
    result.window = window;
    NativeQuery query(display);
    auto read = [&] {
        if (!query.error.isEmpty()) return;
        result.strutAtom = query.atom("_NET_WM_STRUT");
        result.partialAtom = query.atom("_NET_WM_STRUT_PARTIAL");
        const auto tree = query.reply<xcb_query_tree_reply_t>(xcb_query_tree(query.conn, window));
        const auto geometry = query.reply<xcb_get_geometry_reply_t>(xcb_get_geometry(query.conn, window));
        if (!tree || !geometry) return;
        result.root = tree->root;
        const auto root = query.reply<xcb_get_geometry_reply_t>(xcb_get_geometry(query.conn, result.root));
        const auto origin = query.reply<xcb_translate_coordinates_reply_t>(xcb_translate_coordinates(query.conn, window, result.root, 0, 0));
        if (!root || !origin) return;
        result.rootRect = QRect(0, 0, root->width, root->height);
        result.windowRect = QRect(origin->dst_x, origin->dst_y, geometry->width, geometry->height);
        // QScreen origins use Qt's mixed high-DPI coordinate convention. Do
        // not multiply them by DPR: query RandR's actual root-pixel monitor.
        const auto monitors = query.reply<xcb_randr_get_monitors_reply_t>(xcb_randr_get_monitors(query.conn, result.root, 1));
        if (!monitors) return;
        auto iterator = xcb_randr_get_monitors_monitors_iterator(monitors.get());
        for (; iterator.rem; xcb_randr_monitor_info_next(&iterator)) {
            auto *monitor = iterator.data;
            bool matches = false;
            const auto name = query.reply<xcb_get_atom_name_reply_t>(xcb_get_atom_name(query.conn, monitor->name));
            if (name) matches = QByteArray(xcb_get_atom_name_name(name.get()), xcb_get_atom_name_name_length(name.get())) == screenName;
            auto *outputs = xcb_randr_monitor_info_outputs(monitor);
            for (int i = 0; !matches && i < monitor->nOutput; ++i) {
                const auto output = query.reply<xcb_randr_get_output_info_reply_t>(xcb_randr_get_output_info(query.conn, outputs[i], monitors->timestamp));
                if (output) matches = QByteArray(reinterpret_cast<const char *>(xcb_randr_get_output_info_name(output.get())),
                    xcb_randr_get_output_info_name_length(output.get())) == screenName;
            }
            if (matches || monitors->nMonitors == 1) {
                result.monitorRect = QRect(monitor->x, monitor->y, monitor->width, monitor->height);
                result.available = result.monitorRect.isValid();
                break;
            }
        }
        result.strut = query.property(window, result.strutAtom);
        result.partial = query.property(window, result.partialAtom);
        result.frameExtents = query.property(window, query.atom("_NET_FRAME_EXTENTS"));
    };
    read();
    result.error = query.error;
    if (!result.error.isEmpty()) result.available = false;
    else if (!result.available) result.error = "No matching native RandR monitor";
    result.readbackAt = QDateTime::currentMSecsSinceEpoch();
    return result;
}
int edgeIndex(const QString &edge) {
    if (edge == "left") return 0;
    if (edge == "right") return 1;
    if (edge == "top") return 2;
    if (edge == "bottom") return 3;
    return -1;
}
}

PanelReservation::PanelReservation(QObject *parent) : QObject(parent) {
    if (qGuiApp) qGuiApp->installNativeEventFilter(this);
}
PanelReservation::~PanelReservation() {
    if (qGuiApp) qGuiApp->removeNativeEventFilter(this);
    clearReservation();
}
void PanelReservation::setTarget(QQuickItem *target) {
    if (mTarget == target) return;
    QObject::disconnect(mTargetConnection);
    mTarget = target;
    if (target) mTargetConnection = connect(target, &QQuickItem::windowChanged, this, &PanelReservation::bindWindow);
    bindWindow(target ? target->window() : nullptr);
    emit targetChanged();
}
void PanelReservation::setEdge(const QString &edge) {
    if (mEdge == edge) return;
    mEdge = edge;
    emit edgeChanged();
    schedule();
}
void PanelReservation::setThickness(qreal thickness) {
    thickness = std::isfinite(thickness) ? std::max(0.0, thickness) : 0;
    if (mThickness == thickness) return;
    mThickness = thickness;
    emit thicknessChanged();
    schedule();
}
void PanelReservation::setPlacement(const QString &placement) {
    if (mPlacement == placement) return;
    mPlacement = placement;
    emit placementChanged();
    schedule();
}
void PanelReservation::bindWindow(QQuickWindow *window) {
    if (mWindow == window) return;
    clearReservation();
    if (mWindow) mWindow->removeEventFilter(this);
    for (auto &conn : mWindowConnections) QObject::disconnect(conn);
    mWindowConnections.clear();
    mWindow = window;
    mWindowId = 0;
    mNativeState.reset();
    ++mGeneration;
    if (window) {
        window->installEventFilter(this);
        mWindowConnections << connect(window, &QWindow::screenChanged, this, &PanelReservation::bindScreen);
        mWindowConnections << connect(window, &QWindow::visibleChanged, this, [this] { schedule(); });
    }
    bindScreen(window ? window->screen() : nullptr);
    schedule();
}
void PanelReservation::bindScreen(QScreen *screen) {
    for (auto &conn : mScreenConnections) QObject::disconnect(conn);
    mScreenConnections.clear();
    mScreen = screen;
    mNativeState.reset();
    ++mGeneration;
    if (screen) {
        mScreenConnections << connect(screen, &QScreen::geometryChanged, this, [this] { schedule(); });
        mScreenConnections << connect(screen, &QScreen::virtualGeometryChanged, this, [this] { schedule(); });
        mScreenConnections << connect(screen, &QScreen::physicalDotsPerInchChanged, this, [this] { schedule(); });
    }
    schedule();
}
void PanelReservation::schedule() {
    if (mScheduled) return;
    mScheduled = true;
    QTimer::singleShot(0, this, [this] { mScheduled = false; sync(); });
}
bool PanelReservation::eventFilter(QObject *watched, QEvent *event) {
    if (watched == mWindow && (event->type() == QEvent::Move || event->type() == QEvent::Resize
        || event->type() == QEvent::PlatformSurface || event->type() == QEvent::DevicePixelRatioChange)) schedule();
    return false;
}
bool PanelReservation::nativeEventFilter(const QByteArray &type, void *message, qintptr *) {
    if (type != "xcb_generic_event_t" || !mWindowId) return false;
    auto *event = static_cast<xcb_generic_event_t *>(message);
    if ((event->response_type & 0x7f) == XCB_PROPERTY_NOTIFY) {
        auto *propertyEvent = reinterpret_cast<xcb_property_notify_event_t *>(event);
        // Quickshell can rewrite its logical-pixel strut after a geometry
        // update. Reconcile the owned window only, and write only on a change.
        if (propertyEvent->window == mWindowId &&
            (propertyEvent->atom == mStrutAtom || propertyEvent->atom == mPartialAtom)) schedule();
    }
    return false;
}
void PanelReservation::clearReservation() {
    if (auto *conn = connection(); conn && mOwnsReservation && mWindow && mWindow->handle()) {
        xcb_delete_property(conn, mWindowId, mStrutAtom);
        xcb_delete_property(conn, mWindowId, mPartialAtom);
        xcb_flush(conn);
    }
    mOwnsReservation = false;
}
void PanelReservation::publish() {
    const auto observed = inspect();
    if (observed != mObserved) {
        mObserved = observed;
        emit observedChanged();
    }
}
void PanelReservation::sync() {
    auto *conn = connection();
    if (!conn || !mWindow || !mWindow->handle() || !mWindow->screen()) {
        mNativeState.reset();
        publish();
        return;
    }
    if (mWindow->isVisible() && mWindow->screen()->geometry().isValid()) {
        const auto screen = mWindow->screen()->geometry();
        auto desired = mWindow->geometry();
        if (mPlacement == "screen") desired = screen;
        else if (mPlacement == "top-left" || mPlacement == "top-right"
                 || mPlacement == "bottom-left" || mPlacement == "bottom-right") {
            desired.moveLeft(mPlacement.endsWith("left") ? screen.left() : screen.right() - desired.width() + 1);
            desired.moveTop(mPlacement.startsWith("top") ? screen.top() : screen.bottom() - desired.height() + 1);
        }
        // Quickshell 0.3.1 changes exclusionMode without always recomputing
        // its own X11 geometry. Reconcile only the explicitly opted-in owned
        // surface, using the real QScreen, on geometry/screen events.
        if (desired != mWindow->geometry()) mWindow->setGeometry(desired);
    }
    mWindowId = mWindow->winId();
    if (mQueryPending) {
        mRepeatQuery = true;
        return;
    }
    mQueryPending = true;
    mQueryTimedOut = false;
    const auto generation = mGeneration;
    const auto windowId = mWindowId;
    const auto screenName = mWindow->screen()->name().toUtf8();
    const auto screenGeometry = mWindow->screen()->geometry();
    const auto dpr = mWindow->devicePixelRatio();
    auto *watcher = new QFutureWatcher<PanelNativeState>(this);
    connect(watcher, &QFutureWatcher<PanelNativeState>::finished, this,
        [this, watcher, generation, windowId, screenName, screenGeometry, dpr] {
            const auto native = watcher->result();
            watcher->deleteLater();
            mQueryPending = false;
            mQueryTimedOut = false;
            const bool repeat = std::exchange(mRepeatQuery, false);
            // A destroyed/replaced window, hotplug or DPR transition must
            // never apply an old query to a new target (or a reused XID).
            if (generation != mGeneration || !mWindow || !mWindow->handle()
                || mWindow->winId() != windowId || !mWindow->screen()
                || mWindow->screen()->name().toUtf8() != screenName
                || mWindow->screen()->geometry() != screenGeometry
                || !qFuzzyCompare(mWindow->devicePixelRatio(), dpr)) {
                schedule();
                return;
            }
            mNativeState = std::make_shared<PanelNativeState>(native);
            const bool changed = applyNativeState(native);
            publish();
            if (repeat || changed) schedule();
        });
    // Also bound the externally visible Pending state. XCB's initial auth
    // handshake or a queued thread-pool task can stall before reply polling;
    // never keep the UI pending indefinitely, and never queue extra workers
    // while that one is stalled. Recovery still follows actual events/results.
    QTimer::singleShot(3000, watcher, [this, watcher] {
        if (watcher->isFinished()) return;
        mQueryTimedOut = true;
        mNativeState.reset();
        publish();
    });
    watcher->setFuture(QtConcurrent::run(queryNative, qgetenv("DISPLAY"), windowId, screenName));
    publish();
}
bool PanelReservation::applyNativeState(const PanelNativeState &native) {
    auto *conn = connection();
    if (!conn || !mWindow || !native.window) return false;
    if (native.strutAtom) mStrutAtom = native.strutAtom;
    if (native.partialAtom) mPartialAtom = native.partialAtom;
    if (!mStrutAtom || !mPartialAtom) return false;
    const int side = edgeIndex(mEdge);
    bool changed = false;
    if (!native.available || !mWindow->isVisible() || side < 0 || mThickness <= 0) {
        if (!native.strut.empty() || !native.partial.empty() || mOwnsReservation) {
            xcb_delete_property(conn, mWindowId, mStrutAtom);
            xcb_delete_property(conn, mWindowId, mPartialAtom);
            changed = true;
        }
        mOwnsReservation = false;
    } else {
        const auto &monitor = native.monitorRect;
        const auto &root = native.rootRect;
        const int limit = side < 2 ? monitor.width() : monitor.height();
        const int pixels = int(std::min<double>(limit, std::ceil(mThickness * mWindow->devicePixelRatio())));
        std::array<quint32, 12> values{};
        const int offset = side == 0 ? monitor.left() : side == 1 ? root.width() - monitor.right() - 1
            : side == 2 ? monitor.top() : root.height() - monitor.bottom() - 1;
        values[side] = std::max(0, offset + pixels);
        const int start = side < 2 ? monitor.top() : monitor.left();
        const int end = side < 2 ? monitor.bottom() : monitor.right();
        values[4 + side * 2] = std::max(0, start);
        values[5 + side * 2] = std::min(side < 2 ? root.height() - 1 : root.width() - 1, end);
        auto write = [&](quint32 name, const std::vector<quint32> &current, int count) {
            if (current.size() != size_t(count) || !std::equal(current.begin(), current.end(), values.begin())) {
                xcb_change_property(conn, XCB_PROP_MODE_REPLACE, mWindowId, name,
                    XCB_ATOM_CARDINAL, 32, count, values.data());
                changed = true;
            }
        };
        write(mStrutAtom, native.strut, 4);
        write(mPartialAtom, native.partial, 12);
        mOwnsReservation = true;
    }
    // Reply-free requests only. All readback/round-trip waits stay off-thread.
    if (changed) xcb_flush(conn);
    return changed;
}
QVariantMap PanelReservation::inspect(QQuickItem *visual) const {
    const auto native = mNativeState;
    const bool available = native && native->available && native->window == mWindowId;
    QVariantMap result{{"available", available}, {"edge", mEdge}, {"thickness", mThickness}, {"placement", mPlacement},
        {"platform", QGuiApplication::platformName()}, {"state", mQueryTimedOut ? "Unavailable" : mQueryPending ? "Pending" : available ? "Ready" : "Unavailable"}};
    if (mQueryTimedOut) result.insert("error", "Native placement readback deadline exceeded");
    if (native) {
        result.insert("readbackAt", native->readbackAt);
        result.insert("error", native->error);
    }
    if (!mWindow) return result;
    const auto dpr = mWindow->devicePixelRatio();
    result.insert("dpr", dpr);
    result.insert("visible", mWindow->isVisible());
    result.insert("qtRect", rectMap(mWindow->geometry()));
    result.insert("screen", mWindow->screen() ? mWindow->screen()->name() : QString());
    if (!available) return result;
    result.insert("nativeId", QString("0x%1").arg(native->window, 0, 16));
    result.insert("nativeRect", rectMap(native->windowRect));
    QVariantList frameExtents;
    for (auto value : native->frameExtents) frameExtents << value;
    result.insert("frameExtents", frameExtents);
    if (native->frameExtents.size() == 4) {
        const auto &extents = native->frameExtents;
        result.insert("frameRect", rectMap(QRect(native->windowRect.x() - int(extents[0]),
            native->windowRect.y() - int(extents[2]), native->windowRect.width() + int(extents[0]) + int(extents[1]),
            native->windowRect.height() + int(extents[2]) + int(extents[3]))));
    }
    result.insert("monitorRect", rectMap(native->monitorRect));
    result.insert("rootRect", rectMap(native->rootRect));
    QVariantList strut;
    for (auto value : native->partial) strut << value;
    result.insert("strut", strut);
    if (visual && visual->window() == mWindow) {
        const auto local = visual->mapRectToScene(QRectF(0, 0, visual->width(), visual->height()));
        result.insert("visualRect", rectMap(QRectF(native->windowRect.x() + local.x() * dpr,
            native->windowRect.y() + local.y() * dpr, local.width() * dpr, local.height() * dpr)));
    }
    return result;
}
