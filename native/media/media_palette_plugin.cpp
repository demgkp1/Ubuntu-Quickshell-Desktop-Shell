#include "media_palette_plugin.h"

#include "media_palette_backend.h"
#include <QFutureWatcher>
#include <QNetworkRequest>
#include <QUrl>
#include <QTimer>
#include <QtConcurrent>

MediaPalettePlugin::MediaPalettePlugin(QObject *parent) : QObject(parent)
{
    const MediaPalette palette = MediaPaletteBackend::fallbackPalette(QColor(QStringLiteral("#88d0ec")));
    applyPalette(palette.primary, palette.onPrimary, palette.track);
}

QColor MediaPalettePlugin::primary() const { return m_primary; }

QColor MediaPalettePlugin::onPrimary() const { return m_onPrimary; }

QColor MediaPalettePlugin::track() const { return m_track; }

void MediaPalettePlugin::extract(const QString &artUrl, const QColor &fallback)
{
    const QString normalizedArtUrl = artUrl.trimmed();
    const QColor normalizedFallback = fallback.isValid() ? fallback : QColor(QStringLiteral("#88d0ec"));

    if (normalizedArtUrl == m_lastArtUrl && normalizedFallback == m_lastFallback)
        return;

    m_lastArtUrl = normalizedArtUrl;
    m_lastFallback = normalizedFallback;

    const quint64 generation = ++m_generation;
    if (m_reply) m_reply->abort();
    m_available = false;
    m_error.clear();
    const auto fallbackPalette = MediaPaletteBackend::fallbackPalette(normalizedFallback);
    applyPalette(fallbackPalette.primary, fallbackPalette.onPrimary, fallbackPalette.track);
    emit paletteChanged();
    const QUrl url(normalizedArtUrl);
    if (url.scheme() == "http" || url.scheme() == "https") {
        QNetworkRequest request(url);
        request.setTransferTimeout(3000);
        auto *reply = m_network.get(request);
        m_reply = reply;
        QTimer::singleShot(3000, reply, [reply]() { if (!reply->isFinished()) reply->abort(); });
        connect(reply, &QNetworkReply::readyRead, this, [reply]() {
            if (reply->bytesAvailable() > 8 * 1024 * 1024) reply->abort();
        });
        connect(reply, &QNetworkReply::finished, this, [this, reply, generation, normalizedFallback]() {
            const QByteArray bytes = reply->readAll();
            const bool ok = reply->error() == QNetworkReply::NoError && bytes.size() <= 8 * 1024 * 1024;
            reply->deleteLater();
            if (generation != m_generation) return;
            if (!ok) {
                m_error = QStringLiteral("Cover download failed or exceeded 8 MiB");
                emit paletteChanged();
                return;
            }
            analyze([bytes, normalizedFallback]() {
                return MediaPaletteBackend::extractImage(QImage::fromData(bytes), normalizedFallback);
            }, generation);
        });
    } else {
        analyze([normalizedArtUrl, normalizedFallback]() {
            return MediaPaletteBackend::extract(normalizedArtUrl, normalizedFallback);
        }, generation);
    }
}

void MediaPalettePlugin::analyze(std::function<MediaPalette()> work, quint64 generation)
{
    auto *watcher = new QFutureWatcher<MediaPalette>(this);
    connect(watcher, &QFutureWatcher<MediaPalette>::finished, this, [this, watcher, generation]() {
        const auto palette = watcher->result();
        watcher->deleteLater();
        if (generation != m_generation) return;
        m_available = palette.extracted;
        m_error = m_available || m_lastArtUrl.isEmpty() ? QString() : QStringLiteral("Cover could not be decoded; using theme fallback");
        applyPalette(palette.primary, palette.onPrimary, palette.track);
        emit paletteChanged();
    });
    QTimer::singleShot(3000, watcher, [this, watcher, generation]() {
        if (generation == m_generation && !watcher->isFinished()) {
            ++m_generation;
            m_available = false;
            m_error = QStringLiteral("Cover analysis timed out; using theme fallback");
            emit paletteChanged();
        }
    });
    watcher->setFuture(QtConcurrent::run(std::move(work)));
}

bool MediaPalettePlugin::applyPalette(const QColor &primary, const QColor &onPrimary, const QColor &track)
{
    if (m_primary == primary && m_onPrimary == onPrimary && m_track == track) {
        return false;
    }

    m_primary = primary;
    m_onPrimary = onPrimary;
    m_track = track;
    return true;
}
