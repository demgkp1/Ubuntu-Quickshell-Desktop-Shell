#include "window_decoration.h"
#include <QQuickWindow>

bool WindowDecoration::makeFrameless(QQuickItem *item)
{
    auto *window = item ? item->window() : nullptr;
    if (!window)
        return false;
    window->setFlag(Qt::FramelessWindowHint, true);
    return window->flags().testFlag(Qt::FramelessWindowHint);
}
