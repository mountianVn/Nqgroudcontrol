#pragma once

#include <QtQml/QQmlAbstractUrlInterceptor>

#include "QGCCorePlugin.h"
#include "CustomOptions.h"

class CustomOverrideInterceptor;

class CustomPlugin : public QGCCorePlugin
{
    Q_OBJECT

public:
    explicit CustomPlugin(QObject *parent = nullptr);

    static QGCCorePlugin *instance();

    QGCOptions *options() final { return _options; }
    const QVariantList &analyzePages() final;
    QQmlApplicationEngine *createQmlApplicationEngine(QObject *parent) final;

private:
    CustomOptions *_options = nullptr;
    CustomOverrideInterceptor *_selector = nullptr;
    QVariantList _analyzePages;
    bool _analyzePagesInitialized = false;
};

class CustomOverrideInterceptor : public QQmlAbstractUrlInterceptor
{
public:
    QUrl intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type) final;
};
