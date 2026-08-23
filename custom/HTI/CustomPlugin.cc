#include "CustomPlugin.h"

#include <QtCore/QApplicationStatic>
#include <QtCore/QFile>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>

#include "AudioOutput.h"
#include "CustomOptions.h"
#include "QGCApplication.h"
#include "QmlComponentInfo.h"
#include "Voice/HTIVoiceManager.h"

Q_APPLICATION_STATIC(CustomPlugin, customPluginInstance);  // NOLINT(cppcoreguidelines-avoid-non-const-global-variables):
                                                           // Required application-lifetime singleton.

CustomPlugin::CustomPlugin(QObject* parent)
    : QGCCorePlugin(parent), _options(new CustomOptions(this, this)), _voiceManager(new HTIVoiceManager(this))
{
    if (qgcApp() != nullptr) {
        connect(qgcApp(), &QGCApplication::languageChanged, this, &CustomPlugin::_syncCoreSpeechForLanguage);
        _syncCoreSpeechForLanguage(qgcApp()->getCurrentLanguage());
    }
}

void CustomPlugin::_syncCoreSpeechForLanguage(const QLocale& locale)
{
    AudioOutput::instance()->setSpeechSuppressed(locale.language() == QLocale::Vietnamese);
}

QGCCorePlugin* CustomPlugin::instance()
{
    return customPluginInstance();
}

const QVariantList& CustomPlugin::analyzePages()
{
    if (!_analyzePagesInitialized) {
        _analyzePages = QGCCorePlugin::analyzePages();
        _analyzePages.append(QVariant::fromValue(
            new QmlComponentInfo(QStringLiteral("NGroundControl Test Panel"),
                                 QUrl::fromUserInput(QStringLiteral("qrc:/qml/HTI/HTITestPanel.qml")), QUrl(), this)));
        _analyzePagesInitialized = true;
    }

    return _analyzePages;
}

QQmlApplicationEngine* CustomPlugin::createQmlApplicationEngine(QObject* parent)
{
    QQmlApplicationEngine* engine = QGCCorePlugin::createQmlApplicationEngine(parent);
    engine->rootContext()->setContextProperty(QStringLiteral("htiVoiceManager"), _voiceManager);
    engine->addImportPath(QStringLiteral("qrc:/qml/HTI"));
    _selector = new CustomOverrideInterceptor;
    engine->addUrlInterceptor(_selector);
    return engine;
}

QUrl CustomOverrideInterceptor::intercept(const QUrl& url, QQmlAbstractUrlInterceptor::DataType type)
{
    switch (type) {
        case QQmlAbstractUrlInterceptor::QmlFile:
        case QQmlAbstractUrlInterceptor::UrlString:
            if (url.scheme() == QStringLiteral("qrc")) {
                const QString overrideResource = QStringLiteral(":/Custom%1").arg(url.path());
                if (QFile::exists(overrideResource)) {
                    QUrl result;
                    result.setScheme(QStringLiteral("qrc"));
                    result.setPath(overrideResource.mid(2));
                    return result;
                }
            }
            break;
        default:
            break;
    }

    return url;
}
