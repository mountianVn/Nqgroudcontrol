#pragma once

#include <QtQml/QQmlAbstractUrlInterceptor>

#include "CustomOptions.h"
#include "QGCCorePlugin.h"

class CustomOverrideInterceptor;
class HTIVoiceManager;
class QLocale;

class CustomPlugin : public QGCCorePlugin
{
    Q_OBJECT

public:
    explicit CustomPlugin(QObject* parent = nullptr);

    static QGCCorePlugin* instance();

    QGCOptions* options() final { return _options; }

    const QVariantList& analyzePages() final;
    QQmlApplicationEngine* createQmlApplicationEngine(QObject* parent) final;

private:
    static void _syncCoreSpeechForLanguage(const QLocale& locale);

    CustomOptions* _options = nullptr;
    HTIVoiceManager* _voiceManager = nullptr;
    CustomOverrideInterceptor* _selector = nullptr;
    QVariantList _analyzePages;
    bool _analyzePagesInitialized = false;
};

class CustomOverrideInterceptor : public QQmlAbstractUrlInterceptor
{
public:
    QUrl intercept(const QUrl& url, QQmlAbstractUrlInterceptor::DataType type) final;
};
