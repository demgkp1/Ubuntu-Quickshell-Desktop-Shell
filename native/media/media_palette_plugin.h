#pragma once

#include <QObject>
#include <QColor>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QPointer>
#include <functional>
#include "media_palette_backend.h"
#include <QtQml/qqmlregistration.h>

class MediaPalettePlugin : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool available READ available NOTIFY paletteChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY paletteChanged)
    Q_PROPERTY(QColor primary READ primary NOTIFY paletteChanged)
    Q_PROPERTY(QColor onPrimary READ onPrimary NOTIFY paletteChanged)
    Q_PROPERTY(QColor track READ track NOTIFY paletteChanged)

  public:
    explicit MediaPalettePlugin(QObject *parent = nullptr);
    ~MediaPalettePlugin() override = default;

    bool available() const { return m_available; }
    QString errorString() const { return m_error; }
    QColor primary() const;
    QColor onPrimary() const;
    QColor track() const;

    Q_INVOKABLE void extract(const QString &artUrl, const QColor &fallback);

  signals:
    void paletteChanged();

  private:
    bool applyPalette(const QColor &primary, const QColor &onPrimary, const QColor &track);

    void analyze(std::function<MediaPalette()> work, quint64 generation);
    QNetworkAccessManager m_network;
    QPointer<QNetworkReply> m_reply;
    quint64 m_generation = 0;
    bool m_available = false;
    QString m_error;
    QString m_lastArtUrl;
    QColor m_lastFallback;
    QColor m_primary;
    QColor m_onPrimary;
    QColor m_track;
};
