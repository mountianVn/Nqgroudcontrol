#include "CustomPlugin.h"

#include "CustomOptions.h"
#include "QmlComponentInfo.h"

#include <QtCore/QApplicationStatic>
#include <QtCore/QFile>
#include <QtQml/QQmlApplicationEngine>

Q_APPLICATION_STATIC(CustomPlugin, _customPluginInstance);

CustomPlugin::CustomPlugin(QObject *parent)
    : QGCCorePlugin(parent)
    , _options(new CustomOptions(this, this))
{
}

QGCCorePlugin *CustomPlugin::instance()
{
    return _customPluginInstance();
}

const QVariantList &CustomPlugin::analyzePages()
{
    if (!_analyzePagesInitialized) {
        _analyzePages = QGCCorePlugin::analyzePages();
        _analyzePages.append(QVariant::fromValue(new QmlComponentInfo(
            QStringLiteral("NGroundControl Test Panel"),
            QUrl::fromUserInput(QStringLiteral("qrc:/qml/HTI/HTITestPanel.qml")),
            QUrl(),
            this)));
        _analyzePagesInitialized = true;
    }

    return _analyzePages;
}

QQmlApplicationEngine *CustomPlugin::createQmlApplicationEngine(QObject *parent)
{
    QQmlApplicationEngine *engine = QGCCorePlugin::createQmlApplicationEngine(parent);
    engine->addImportPath(QStringLiteral("qrc:/qml/HTI"));
    _selector = new CustomOverrideInterceptor;
    engine->addUrlInterceptor(_selector);
    return engine;
}

QUrl CustomOverrideInterceptor::intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type)
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
