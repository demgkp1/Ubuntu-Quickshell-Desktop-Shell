#pragma once
#include <QAbstractNativeEventFilter>
#include <QObject>
#include <QPointer>
#include <QQuickItem>
#include <QQuickWindow>
#include <QScreen>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>
#include <memory>

struct PanelNativeState;

// Maintain physical-screen canvases/corners and EWMH's native-pixel struts.
// Never changes another application's geometry or flags. The target must be
// a QQuickItem owned by this process, not an arbitrary X11 window ID.
class PanelReservation : public QObject, public QAbstractNativeEventFilter {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QQuickItem *target READ target WRITE setTarget NOTIFY targetChanged)
    Q_PROPERTY(QString edge READ edge WRITE setEdge NOTIFY edgeChanged)
    Q_PROPERTY(qreal thickness READ thickness WRITE setThickness NOTIFY thicknessChanged)
    Q_PROPERTY(QString placement READ placement WRITE setPlacement NOTIFY placementChanged)
    Q_PROPERTY(QVariantMap observed READ observed NOTIFY observedChanged)
public:
    explicit PanelReservation(QObject *parent = nullptr);
    ~PanelReservation() override;
    QQuickItem *target() const { return mTarget; }
    QString edge() const { return mEdge; }
    qreal thickness() const { return mThickness; }
    QString placement() const { return mPlacement; }
    QVariantMap observed() const { return mObserved; }
    void setTarget(QQuickItem *target);
    void setEdge(const QString &edge);
    void setThickness(qreal thickness);
    void setPlacement(const QString &placement);
    Q_INVOKABLE QVariantMap inspect(QQuickItem *visual = nullptr) const;
    bool nativeEventFilter(const QByteArray &, void *message, qintptr *) override;
    bool eventFilter(QObject *watched, QEvent *event) override;
signals:
    void targetChanged();
    void edgeChanged();
    void thicknessChanged();
    void placementChanged();
    void observedChanged();
private:
    void bindWindow(QQuickWindow *window);
    void bindScreen(QScreen *screen);
    void schedule();
    void sync();
    void clearReservation();
    void publish();
    bool applyNativeState(const PanelNativeState &native);
    QPointer<QQuickItem> mTarget;
    QPointer<QQuickWindow> mWindow;
    QPointer<QScreen> mScreen;
    QMetaObject::Connection mTargetConnection;
    QList<QMetaObject::Connection> mWindowConnections;
    QList<QMetaObject::Connection> mScreenConnections;
    QString mEdge;
    QString mPlacement;
    qreal mThickness = 0;
    QVariantMap mObserved;
    bool mScheduled = false;
    bool mOwnsReservation = false;
    bool mQueryPending = false;
    bool mQueryTimedOut = false;
    bool mRepeatQuery = false;
    quint64 mGeneration = 0;
    std::shared_ptr<const PanelNativeState> mNativeState;
    quint32 mWindowId = 0;
    quint32 mStrutAtom = 0;
    quint32 mPartialAtom = 0;
};
