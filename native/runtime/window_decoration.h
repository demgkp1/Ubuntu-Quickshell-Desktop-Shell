#pragma once
#include <QObject>
#include <QQuickItem>
#include <QtQml/qqmlregistration.h>

// Only accepts items in this process. Never enumerates or changes other clients.
class WindowDecoration : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
  public:
    explicit WindowDecoration(QObject *parent = nullptr) : QObject(parent) {}
    Q_INVOKABLE bool makeFrameless(QQuickItem *item);
};
