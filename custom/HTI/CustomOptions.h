#pragma once

#include "QGCOptions.h"

class CustomPlugin;
class CustomOptions;

class CustomFlyViewOptions : public QGCFlyViewOptions
{
    Q_OBJECT

public:
    explicit CustomFlyViewOptions(CustomOptions *options, QObject *parent = nullptr);
};

class CustomOptions : public QGCOptions
{
    Q_OBJECT

public:
    explicit CustomOptions(CustomPlugin *plugin, QObject *parent = nullptr);

    QGCFlyViewOptions *flyViewOptions() const final { return _flyViewOptions; }

private:
    CustomPlugin *_plugin = nullptr;
    CustomFlyViewOptions *_flyViewOptions = nullptr;
};
