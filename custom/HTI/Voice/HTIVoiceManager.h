#pragma once

#include <QtCore/QHash>
#include <QtCore/QLocale>
#include <QtCore/QPointer>
#include <QtCore/QQueue>
#include <QtCore/QString>
#include <QtCore/QTimer>
#include <QtCore/QUrl>
#include <QtMultimedia/QAudioOutput>
#include <QtMultimedia/QMediaPlayer>

class Vehicle;

class HTIVoiceManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QString language READ language CONSTANT)
    Q_PROPERTY(QString voicePackName READ voicePackName CONSTANT)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool audioPackAvailable READ audioPackAvailable NOTIFY availabilityChanged)
    Q_PROPERTY(bool activeForCurrentLanguage READ activeForCurrentLanguage NOTIFY availabilityChanged)
    Q_PROPERTY(QString status READ status NOTIFY availabilityChanged)
    Q_PROPERTY(bool connectionAlerts READ connectionAlerts WRITE setConnectionAlerts NOTIFY groupSettingsChanged)
    Q_PROPERTY(bool flightModeAlerts READ flightModeAlerts WRITE setFlightModeAlerts NOTIFY groupSettingsChanged)
    Q_PROPERTY(bool batteryAlerts READ batteryAlerts WRITE setBatteryAlerts NOTIFY groupSettingsChanged)
    Q_PROPERTY(bool gpsAlerts READ gpsAlerts WRITE setGpsAlerts NOTIFY groupSettingsChanged)
    Q_PROPERTY(bool preFlightAlerts READ preFlightAlerts WRITE setPreFlightAlerts NOTIFY groupSettingsChanged)
    Q_PROPERTY(bool missionAlerts READ missionAlerts WRITE setMissionAlerts NOTIFY groupSettingsChanged)

public:
    explicit HTIVoiceManager(QObject* parent = nullptr);

    bool enabled() const { return _enabled; }

    void setEnabled(bool enabled);

    QString language() const { return QStringLiteral("vi-VN"); }

    QString voicePackName() const { return tr("HTI Vietnamese WAV Voice Pack"); }

    double volume() const { return _volume; }

    void setVolume(double volume);

    bool audioPackAvailable() const { return _audioPackAvailable; }

    bool activeForCurrentLanguage() const { return _vietnameseUiActive; }

    QString status() const { return _status; }

    bool connectionAlerts() const { return _connectionAlerts; }

    bool flightModeAlerts() const { return _flightModeAlerts; }

    bool batteryAlerts() const { return _batteryAlerts; }

    bool gpsAlerts() const { return _gpsAlerts; }

    bool preFlightAlerts() const { return _preFlightAlerts; }

    bool missionAlerts() const { return _missionAlerts; }

    void setConnectionAlerts(bool value) { _setGroupSetting(_connectionAlerts, value, "connectionAlerts"); }

    void setFlightModeAlerts(bool value) { _setGroupSetting(_flightModeAlerts, value, "flightModeAlerts"); }

    void setBatteryAlerts(bool value) { _setGroupSetting(_batteryAlerts, value, "batteryAlerts"); }

    void setGpsAlerts(bool value) { _setGroupSetting(_gpsAlerts, value, "gpsAlerts"); }

    void setPreFlightAlerts(bool value) { _setGroupSetting(_preFlightAlerts, value, "preFlightAlerts"); }

    void setMissionAlerts(bool value) { _setGroupSetting(_missionAlerts, value, "missionAlerts"); }

    Q_INVOKABLE void testVoice();
    Q_INVOKABLE void speakEvent(const QString& event, int priority = 1, const QString& detail = QString());

signals:
    void enabledChanged();
    void volumeChanged();
    void availabilityChanged();
    void groupSettingsChanged();

private slots:
    void _vehicleAdded(Vehicle* vehicle);
    void _vehicleRemoved(Vehicle* vehicle);
    void _activeVehicleChanged(Vehicle* vehicle);
    void _pollVehicleState();

private:
    enum Priority
    {
        Info = 0,
        Warning = 1,
        Critical = 2
    };

    void _loadSettings();
    void _updateLanguage(const QLocale& locale);
    void _play(const QUrl& source, Priority priority);
    void _playSequence(const QList<QUrl>& sources, Priority priority);
    void _playNextAudioSegment();
    static QUrl _audioSource(const QString& event, const QString& detail);
    static QUrl _audioUrl(const QString& file);
    QList<QUrl> _numberAudioSequence(int value) const;
    QList<QUrl> _decimalAudioSequence(double value) const;
    void _announceDistanceToHome(double meters);
    void _announceTotalDistance(double meters);
    void _appendDistanceValue(QList<QUrl>& sequence, double meters) const;
    void _announceAltitude(double meters);
    void _announceBattery(int percent);
    void _resetDynamicAnnouncementState();
    void _handleStatusText(const QString& text);
    bool _groupAllows(const QString& event) const;
    void _setGroupSetting(bool& target, bool value, const char* key);
    bool _cooldownAllows(const QString& key, int cooldownMs);

    QMediaPlayer* _player = nullptr;
    QAudioOutput* _audioOutput = nullptr;
    QQueue<QUrl> _audioQueue;
    QTimer _pollTimer;
    QPointer<Vehicle> _vehicle;
    QString _status;
    bool _enabled = true;
    bool _audioPackAvailable = false;
    bool _vietnameseUiActive = false;
    bool _englishUiActive = false;
    bool _sequenceActive = false;
    int _lastGpsLock = -1;
    int _lastGpsJammingState = -1;
    int _lastGpsSpoofingState = -1;
    double _lastBatteryPercent = -1.0;
    int _lastHomeDistanceAnnouncementStep = -1;
    int _lastHomeDistanceBelowOneKmStep = -1;
    double _nextTotalDistanceAnnouncementMeters = 3000.0;
    int _lastAltitudeAnnouncementStep = -1;
    int _lastAltitudeBelowFiftyMetersStep = -1;
    bool _hasAnnouncedAltitudeBelowOneMeter = false;
    double _lastRelativeAltitudeMeters = -1.0;
    double _lastBatteryVoicePercent = -1.0;
    QHash<QString, qint64> _lastSpoken;
    double _volume = 1.0;
    bool _connectionAlerts = true;
    bool _flightModeAlerts = true;
    bool _batteryAlerts = true;
    bool _gpsAlerts = true;
    bool _preFlightAlerts = true;
    bool _missionAlerts = true;
};
