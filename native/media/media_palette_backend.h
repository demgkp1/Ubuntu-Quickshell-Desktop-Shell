#pragma once

#include <QColor>
#include <QString>
#include <QImage>

struct MediaPalette {
    QColor primary;
    QColor onPrimary;
    QColor track;
    bool extracted = false;
};

class MediaPaletteBackend {
  public:
    static MediaPalette extract(const QString &artUrl, const QColor &fallback);
    static MediaPalette extractImage(const QImage &image, const QColor &fallback);
    static MediaPalette fallbackPalette(const QColor &fallback);
};
