#include "HTIVoiceManager.h"

#include <QtCore/QDateTime>
#include <QtCore/QFile>
#include <QtCore/QSettings>
#include <QtCore/QtMath>
#include <array>
#include <cmath>

#include "Fact.h"
#include "FactGroup.h"
#include "MultiVehicleManager.h"
#include "QGCApplication.h"
#include "QmlObjectListModel.h"
#include "Vehicle.h"
#include "Vehicle/FactGroups/BatteryFactGroupListModel.h"

namespace {
constexpr auto AudioResourcePrefix = "qrc:/HTI/Voice/wav/";
constexpr double TotalDistanceAnnouncementIntervalMeters = 3000.0;
constexpr double LowAltitudeAnnouncementStartMeters = 50.0;
constexpr double LowAltitudeAnnouncementIntervalMeters = 10.0;
constexpr qreal VoicePlaybackRate = 1.20;
}  // namespace

HTIVoiceManager::HTIVoiceManager(QObject* parent)
    : QObject(parent), _player(new QMediaPlayer(this)), _audioOutput(new QAudioOutput(this))
{
    _loadSettings();
    _player->setAudioOutput(_audioOutput);
    _player->setPlaybackRate(VoicePlaybackRate);
    _audioOutput->setVolume(static_cast<float>(_volume));
    _audioPackAvailable = QFile::exists(QStringLiteral(":/HTI/Voice/wav/hti_voice_ready.wav"));
    connect(qgcApp(), &QGCApplication::languageChanged, this, &HTIVoiceManager::_updateLanguage);
    _updateLanguage(qgcApp()->getCurrentLanguage());

    connect(_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
        if (state == QMediaPlayer::StoppedState && _sequenceActive) {
            QTimer::singleShot(25, this, &HTIVoiceManager::_playNextAudioSegment);
        }
    });

    connect(_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error, const QString&) {
        if (_player->error() != QMediaPlayer::NoError) {
            _audioPackAvailable = false;
            _status = tr("HTI Vietnamese WAV audio pack unavailable");
            emit availabilityChanged();
        }
    });

    auto* manager = MultiVehicleManager::instance();
    connect(manager, &MultiVehicleManager::vehicleAdded, this, &HTIVoiceManager::_vehicleAdded);
    connect(manager, &MultiVehicleManager::vehicleRemoved, this, &HTIVoiceManager::_vehicleRemoved);
    connect(manager, &MultiVehicleManager::activeVehicleChanged, this, &HTIVoiceManager::_activeVehicleChanged);
    _activeVehicleChanged(manager->activeVehicle());

    connect(&_pollTimer, &QTimer::timeout, this, &HTIVoiceManager::_pollVehicleState);
    _pollTimer.setInterval(1000);
    _pollTimer.start();
}

void HTIVoiceManager::_updateLanguage(const QLocale& locale)
{
    _vietnameseUiActive = locale.language() == QLocale::Vietnamese;
    _englishUiActive = locale.language() == QLocale::English;
    _audioQueue.clear();
    _sequenceActive = false;
    _player->stop();
    if (_englishUiActive) {
        _status = tr("English dynamic WAV alerts are ready");
    } else if (!_vietnameseUiActive) {
        _status = tr("Vietnamese WAV alerts are disabled while English UI is selected");
    } else {
        _status = _audioPackAvailable ? tr("HTI Vietnamese WAV audio pack ready")
                                      : tr("HTI Vietnamese WAV audio pack unavailable");
    }
    emit availabilityChanged();
}

QUrl HTIVoiceManager::_audioUrl(const QString& file)
{
    return QUrl(QString::fromLatin1(AudioResourcePrefix) + file);
}

void HTIVoiceManager::_loadSettings()
{
    QSettings settings;
    settings.beginGroup(QStringLiteral("HTIVoice"));
    _enabled = settings.value(QStringLiteral("enabled"), true).toBool();
    _volume = settings.value(QStringLiteral("volume"), 1.0).toDouble();
    _connectionAlerts = settings.value(QStringLiteral("connectionAlerts"), true).toBool();
    _flightModeAlerts = settings.value(QStringLiteral("flightModeAlerts"), true).toBool();
    _batteryAlerts = settings.value(QStringLiteral("batteryAlerts"), true).toBool();
    _gpsAlerts = settings.value(QStringLiteral("gpsAlerts"), true).toBool();
    _preFlightAlerts = settings.value(QStringLiteral("preFlightAlerts"), true).toBool();
    _missionAlerts = settings.value(QStringLiteral("missionAlerts"), true).toBool();
    settings.endGroup();
}

void HTIVoiceManager::setEnabled(bool enabled)
{
    if (_enabled == enabled) {
        return;
    }
    _enabled = enabled;
    QSettings().setValue(QStringLiteral("HTIVoice/enabled"), enabled);
    emit enabledChanged();
}

void HTIVoiceManager::setVolume(double volume)
{
    _volume = qBound(0.0, volume, 1.0);
    _audioOutput->setVolume(static_cast<float>(_volume));
    QSettings().setValue(QStringLiteral("HTIVoice/volume"), _volume);
    emit volumeChanged();
}

void HTIVoiceManager::_setGroupSetting(bool& target, bool value, const char* key)
{
    if (target == value) {
        return;
    }
    target = value;
    QSettings().setValue(QStringLiteral("HTIVoice/") + QString::fromLatin1(key), value);
    emit groupSettingsChanged();
}

bool HTIVoiceManager::_groupAllows(const QString& event) const
{
    if (event == QLatin1String("connected") || event == QLatin1String("disconnected")) {
        return _connectionAlerts;
    }
    if (event == QLatin1String("armed") || event == QLatin1String("disarmed") || event == QLatin1String("prearm")) {
        return _preFlightAlerts;
    }
    if (event == QLatin1String("rtl") || event == QLatin1String("loiter") || event == QLatin1String("auto")) {
        return _flightModeAlerts;
    }
    if (event == QLatin1String("battery-low") || event == QLatin1String("battery-critical")) {
        return _batteryAlerts;
    }
    if (event == QLatin1String("gps-ready") || event == QLatin1String("gps-degraded")) {
        return _gpsAlerts;
    }
    if (event == QLatin1String("mission-complete")) {
        return _missionAlerts;
    }
    return true;
}

QUrl HTIVoiceManager::_audioSource(const QString& event, const QString& detail)
{
    static const QHash<QString, QString> audioFiles = {
        {QStringLiteral("connected"), QStringLiteral("da_ket_noi_may_bay.wav")},
        {QStringLiteral("disconnected"), QStringLiteral("mat_ket_noi_may_bay.wav")},
        {QStringLiteral("telemetry-lost"), QStringLiteral("mat_du_lieu_telemetry.wav")},
        {QStringLiteral("telemetry-restored"), QStringLiteral("da_khoi_phuc_telemetry.wav")},
        {QStringLiteral("link-weak"), QStringLiteral("tin_hieu_ket_noi_yeu.wav")},
        {QStringLiteral("link-recovered"), QStringLiteral("tin_hieu_ket_noi_da_on_dinh.wav")},
        {QStringLiteral("armed"), QStringLiteral("may_bay_da_arm.wav")},
        {QStringLiteral("disarmed"), QStringLiteral("may_bay_da_disarm.wav")},
        {QStringLiteral("takeoff-started"), QStringLiteral("may_bay_dang_cat_canh.wav")},
        {QStringLiteral("takeoff-complete"), QStringLiteral("may_bay_da_dat_do_cao_cat_canh.wav")},
        {QStringLiteral("landing-started"), QStringLiteral("may_bay_dang_ha_canh.wav")},
        {QStringLiteral("landing-complete"), QStringLiteral("may_bay_da_ha_canh.wav")},
        {QStringLiteral("emergency-land"), QStringLiteral("ha_canh_khan_cap.wav")},
        {QStringLiteral("rtl"), QStringLiteral("dang_ve_home.wav")},
        {QStringLiteral("home-reached"), QStringLiteral("may_bay_da_ve_home.wav")},
        {QStringLiteral("loiter"), QStringLiteral("da_chuyen_loiter.wav")},
        {QStringLiteral("auto"), QStringLiteral("da_chuyen_auto.wav")},
        {QStringLiteral("guided"), QStringLiteral("da_chuyen_guided.wav")},
        {QStringLiteral("manual"), QStringLiteral("da_chuyen_manual.wav")},
        {QStringLiteral("stabilize"), QStringLiteral("da_chuyen_stabilize.wav")},
        {QStringLiteral("altitude-hold"), QStringLiteral("da_chuyen_giu_do_cao.wav")},
        {QStringLiteral("position-hold"), QStringLiteral("da_chuyen_giu_vi_tri.wav")},
        {QStringLiteral("mode-change-failed"), QStringLiteral("khong_the_chuyen_che_do_bay.wav")},
        {QStringLiteral("mission-started"), QStringLiteral("nhiem_vu_da_bat_dau.wav")},
        {QStringLiteral("mission-paused"), QStringLiteral("nhiem_vu_da_tam_dung.wav")},
        {QStringLiteral("mission-resumed"), QStringLiteral("nhiem_vu_da_tiep_tuc.wav")},
        {QStringLiteral("mission-complete"), QStringLiteral("nhiem_vu_da_hoan_thanh.wav")},
        {QStringLiteral("mission-aborted"), QStringLiteral("nhiem_vu_da_huy.wav")},
        {QStringLiteral("waypoint-reached"), QStringLiteral("da_den_waypoint.wav")},
        {QStringLiteral("mission-upload-success"), QStringLiteral("tai_len_nhiem_vu_thanh_cong.wav")},
        {QStringLiteral("mission-upload-failed"), QStringLiteral("tai_len_nhiem_vu_that_bai.wav")},
        {QStringLiteral("gps-ready"), QStringLiteral("gps_da_san_sang.wav")},
        {QStringLiteral("gps-degraded"), QStringLiteral("canh_bao_gps_yeu.wav")},
        {QStringLiteral("gps-acquiring"), QStringLiteral("dang_tim_tin_hieu_gps.wav")},
        {QStringLiteral("gps-lost"), QStringLiteral("mat_tin_hieu_gps.wav")},
        {QStringLiteral("rtk-float"), QStringLiteral("rtk_float.wav")},
        {QStringLiteral("rtk-fixed"), QStringLiteral("rtk_fixed.wav")},
        {QStringLiteral("gps-jamming"), QStringLiteral("canh_bao_gps_bi_nhieu.wav")},
        {QStringLiteral("gps-spoofing"), QStringLiteral("canh_bao_gps_gia_mao.wav")},
        {QStringLiteral("battery-low"), QStringLiteral("canh_bao_pin_yeu.wav")},
        {QStringLiteral("battery-critical"), QStringLiteral("canh_bao_pin_sap_het.wav")},
        {QStringLiteral("battery-30"), QStringLiteral("pin_con_ba_muoi_phan_tram.wav")},
        {QStringLiteral("battery-20"), QStringLiteral("pin_con_hai_muoi_phan_tram.wav")},
        {QStringLiteral("battery-10"), QStringLiteral("pin_con_muoi_phan_tram.wav")},
        {QStringLiteral("battery-missing"), QStringLiteral("khong_nhan_duoc_pin.wav")},
        {QStringLiteral("battery-error"), QStringLiteral("loi_pin.wav")},
        {QStringLiteral("prearm-waiting-rc"), QStringLiteral("prearm_cho_tin_hieu_dieu_khien.wav")},
        {QStringLiteral("prearm-low-voltage"), QStringLiteral("prearm_dien_ap_pin_thap.wav")},
        {QStringLiteral("prearm-compass"), QStringLiteral("prearm_la_ban_chua_san_sang.wav")},
        {QStringLiteral("prearm-gyro"), QStringLiteral("prearm_gyro_khong_on_dinh.wav")},
        {QStringLiteral("prearm-gps"), QStringLiteral("prearm_gps_chua_san_sang.wav")},
        {QStringLiteral("prearm-ekf"), QStringLiteral("prearm_ekf_khong_on_dinh.wav")},
        {QStringLiteral("prearm-accelerometer"), QStringLiteral("prearm_gia_toc_ke.wav")},
        {QStringLiteral("prearm"), QStringLiteral("prearm_kiem_tra_khong_dat.wav")},
        {QStringLiteral("failsafe"), QStringLiteral("failsafe_da_kich_hoat.wav")},
        {QStringLiteral("geofence-breach"), QStringLiteral("vi_pham_hang_rao_dia_ly.wav")},
        {QStringLiteral("obstacle-detected"), QStringLiteral("phat_hien_vat_can.wav")},
        {QStringLiteral("ekf-error"), QStringLiteral("loi_ekf.wav")},
        {QStringLiteral("compass-calibration"), QStringLiteral("can_hieu_chuan_la_ban.wav")},
        {QStringLiteral("home-set"), QStringLiteral("da_dat_diem_home.wav")},
        {QStringLiteral("recording-started"), QStringLiteral("da_bat_dau_ghi_hinh.wav")},
        {QStringLiteral("recording-stopped"), QStringLiteral("da_dung_ghi_hinh.wav")},
        {QStringLiteral("camera-photo"), QStringLiteral("da_chup_anh.wav")},
        {QStringLiteral("test"), QStringLiteral("hti_voice_ready.wav")},
    };

    QString eventKey = event;
    if (event == QLatin1String("prearm")) {
        const QString lower = detail.toLower();
        if (lower.contains(QStringLiteral("waiting for rc"))) {
            eventKey = QStringLiteral("prearm-waiting-rc");
        } else if (lower.contains(QStringLiteral("below minimum arming voltage"))) {
            eventKey = QStringLiteral("prearm-low-voltage");
        } else if (lower.contains(QStringLiteral("compass"))) {
            eventKey = QStringLiteral("prearm-compass");
        } else if (lower.contains(QStringLiteral("gyro"))) {
            eventKey = QStringLiteral("prearm-gyro");
        } else if (lower.contains(QStringLiteral("gps"))) {
            eventKey = QStringLiteral("prearm-gps");
        } else if (lower.contains(QStringLiteral("ekf"))) {
            eventKey = QStringLiteral("prearm-ekf");
        } else if (lower.contains(QStringLiteral("accelerometer"))) {
            eventKey = QStringLiteral("prearm-accelerometer");
        }
    }
    const QString file = audioFiles.value(eventKey);
    return file.isEmpty() ? QUrl() : QUrl(QString::fromLatin1(AudioResourcePrefix) + file);
}

void HTIVoiceManager::testVoice()
{
    speakEvent(QStringLiteral("test"), Info);
}

QList<QUrl> HTIVoiceManager::_numberAudioSequence(int value) const
{
    value = qBound(0, value, 9999);
    QList<QUrl> result;
    auto append = [&result, this](const QString& file) { result.append(_audioUrl(file)); };

    if (_vietnameseUiActive) {
        static const QStringList digits = {"vi_so_khong.wav", "vi_so_mot.wav", "vi_so_hai.wav", "vi_so_ba.wav",
                                           "vi_so_bon.wav",   "vi_so_nam.wav", "vi_so_sau.wav", "vi_so_bay.wav",
                                           "vi_so_tam.wav",   "vi_so_chin.wav"};
        static const QStringList tens = {"",
                                         "vi_muoi.wav",
                                         "vi_hai_muoi.wav",
                                         "vi_ba_muoi.wav",
                                         "vi_bon_muoi.wav",
                                         "vi_nam_muoi.wav",
                                         "vi_sau_muoi.wav",
                                         "vi_bay_muoi.wav",
                                         "vi_tam_muoi.wav",
                                         "vi_chin_muoi.wav"};
        const auto appendUnder100 = [&append](int number) {
            if (number < 10) {
                append(digits.at(number));
            } else if (number < 20) {
                append(QStringLiteral("vi_muoi.wav"));
                if (number % 10 == 5) {
                    append(QStringLiteral("vi_lam.wav"));
                } else if (number % 10 > 0) {
                    append(digits.at(number % 10));
                }
            } else {
                append(tens.at(number / 10));
                const int unit = number % 10;
                if (unit == 1) {
                    append(QStringLiteral("vi_mot_sau_muoi.wav"));
                } else if (unit == 5) {
                    append(QStringLiteral("vi_lam.wav"));
                } else if (unit > 0) {
                    append(digits.at(unit));
                }
            }
        };

        if (value >= 1000) {
            append(digits.at(value / 1000));
            append(QStringLiteral("vi_nghin.wav"));
            value %= 1000;
        }
        if (value >= 100) {
            append(digits.at(value / 100));
            append(QStringLiteral("vi_tram.wav"));
            value %= 100;
        }
        if (value > 0 || result.isEmpty()) {
            appendUnder100(value);
        }
    } else if (_englishUiActive) {
        static const QStringList underTwenty = {
            "en_zero.wav",    "en_one.wav",     "en_two.wav",       "en_three.wav",    "en_four.wav",
            "en_five.wav",    "en_six.wav",     "en_seven.wav",     "en_eight.wav",    "en_nine.wav",
            "en_ten.wav",     "en_eleven.wav",  "en_twelve.wav",    "en_thirteen.wav", "en_fourteen.wav",
            "en_fifteen.wav", "en_sixteen.wav", "en_seventeen.wav", "en_eighteen.wav", "en_nineteen.wav"};
        static const QStringList tens = {"",
                                         "",
                                         "en_twenty.wav",
                                         "en_thirty.wav",
                                         "en_forty.wav",
                                         "en_fifty.wav",
                                         "en_sixty.wav",
                                         "en_seventy.wav",
                                         "en_eighty.wav",
                                         "en_ninety.wav"};
        const auto appendUnder100 = [&append](int number) {
            if (number < 20) {
                append(underTwenty.at(number));
            } else {
                append(tens.at(number / 10));
                if (number % 10 > 0) {
                    append(underTwenty.at(number % 10));
                }
            }
        };

        if (value >= 1000) {
            appendUnder100(value / 1000);
            append(QStringLiteral("en_thousand.wav"));
            value %= 1000;
        }
        if (value >= 100) {
            append(underTwenty.at(value / 100));
            append(QStringLiteral("en_hundred.wav"));
            value %= 100;
            if (value > 0) {
                append(QStringLiteral("en_and.wav"));
            }
        }
        if (value > 0 || result.isEmpty()) {
            appendUnder100(value);
        }
    }
    return result;
}

QList<QUrl> HTIVoiceManager::_decimalAudioSequence(double value) const
{
    const int tenths = qMax(0, qRound(value * 10.0));
    const int whole = tenths / 10;
    const int decimal = tenths % 10;
    QList<QUrl> result = _numberAudioSequence(whole);
    if (_vietnameseUiActive) {
        result.append(_audioUrl(QStringLiteral("vi_phay.wav")));
    } else if (_englishUiActive) {
        result.append(_audioUrl(QStringLiteral("en_point.wav")));
    }
    result.append(_numberAudioSequence(decimal));
    return result;
}

void HTIVoiceManager::_appendDistanceValue(QList<QUrl>& sequence, double meters) const
{
    if (meters < 1000.0) {
        const int distanceMeters = qMax(0, qFloor(meters));
        sequence.append(_numberAudioSequence(distanceMeters));
        if (_vietnameseUiActive) {
            sequence.append(_audioUrl(QStringLiteral("vi_met.wav")));
        } else if (_englishUiActive) {
            sequence.append(
                _audioUrl(distanceMeters == 1 ? QStringLiteral("en_meter.wav") : QStringLiteral("en_meters.wav")));
        }
    } else {
        sequence.append(_decimalAudioSequence(meters / 1000.0));
        if (_vietnameseUiActive) {
            sequence.append(_audioUrl(QStringLiteral("vi_kilomet.wav")));
        } else if (_englishUiActive) {
            sequence.append(_audioUrl(qRound(meters / 100.0) == 10 ? QStringLiteral("en_kilometer.wav")
                                                                   : QStringLiteral("en_kilometers.wav")));
        }
    }
}

void HTIVoiceManager::_announceDistanceToHome(double meters)
{
    QList<QUrl> sequence;
    if (_vietnameseUiActive) {
        sequence.append(_audioUrl(QStringLiteral("vi_khoang_cach_den_home.wav")));
    } else if (_englishUiActive) {
        sequence.append(_audioUrl(QStringLiteral("en_distance_to_home.wav")));
    }
    _appendDistanceValue(sequence, meters);
    _playSequence(sequence, Info);
}

void HTIVoiceManager::_announceTotalDistance(double meters)
{
    QList<QUrl> sequence;
    if (_vietnameseUiActive) {
        sequence.append(_audioUrl(QStringLiteral("vi_tong_quang_duong_da_bay.wav")));
    } else if (_englishUiActive) {
        sequence.append(_audioUrl(QStringLiteral("en_total_distance_traveled.wav")));
    }
    _appendDistanceValue(sequence, meters);
    _playSequence(sequence, Info);
}

void HTIVoiceManager::_announceAltitude(double meters)
{
    QList<QUrl> sequence;
    if (_vietnameseUiActive) {
        sequence.append(_audioUrl(QStringLiteral("vi_do_cao_hien_tai.wav")));
    } else if (_englishUiActive) {
        sequence.append(_audioUrl(QStringLiteral("en_current_altitude.wav")));
    }

    if (meters < 1000.0) {
        const int altitudeMeters = qMax(0, qFloor(meters));
        sequence.append(_numberAudioSequence(altitudeMeters));
        if (_vietnameseUiActive) {
            sequence.append(_audioUrl(QStringLiteral("vi_met.wav")));
        } else if (_englishUiActive) {
            sequence.append(
                _audioUrl(altitudeMeters == 1 ? QStringLiteral("en_meter.wav") : QStringLiteral("en_meters.wav")));
        }
    } else {
        sequence.append(_decimalAudioSequence(meters / 1000.0));
        if (_vietnameseUiActive) {
            sequence.append(_audioUrl(QStringLiteral("vi_kilomet.wav")));
        } else if (_englishUiActive) {
            sequence.append(_audioUrl(qRound(meters / 100.0) == 10 ? QStringLiteral("en_kilometer.wav")
                                                                   : QStringLiteral("en_kilometers.wav")));
        }
    }
    _playSequence(sequence, Info);
}

void HTIVoiceManager::_announceBattery(int percent)
{
    QList<QUrl> sequence;
    if (_vietnameseUiActive) {
        sequence.append(_audioUrl(QStringLiteral("vi_pin_hien_tai.wav")));
    } else if (_englishUiActive) {
        sequence.append(_audioUrl(QStringLiteral("en_current_battery.wav")));
    }
    sequence.append(_numberAudioSequence(percent));
    sequence.append(
        _audioUrl(_vietnameseUiActive ? QStringLiteral("vi_phan_tram.wav") : QStringLiteral("en_percent.wav")));
    _playSequence(sequence, Info);
}

void HTIVoiceManager::_resetDynamicAnnouncementState()
{
    _lastHomeDistanceAnnouncementStep = -1;
    _lastHomeDistanceBelowOneKmStep = -1;
    _nextTotalDistanceAnnouncementMeters = TotalDistanceAnnouncementIntervalMeters;
    _lastAltitudeAnnouncementStep = -1;
    _lastAltitudeBelowFiftyMetersStep = -1;
    _hasAnnouncedAltitudeBelowOneMeter = false;
    _lastRelativeAltitudeMeters = -1.0;
    _lastBatteryVoicePercent = -1.0;
}

bool HTIVoiceManager::_cooldownAllows(const QString& key, int cooldownMs)
{
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (now - _lastSpoken.value(key, 0) < cooldownMs) {
        return false;
    }
    _lastSpoken.insert(key, now);
    return true;
}

void HTIVoiceManager::_play(const QUrl& source, Priority priority)
{
    if (!_enabled || !_audioPackAvailable || !_vietnameseUiActive || source.isEmpty()) {
        return;
    }
    const bool playerIsActive = _player->playbackState() == QMediaPlayer::PlayingState;
    if (priority == Critical && (playerIsActive || _sequenceActive)) {
        _audioQueue.clear();
        _sequenceActive = false;
        _player->stop();
    } else if (playerIsActive || _sequenceActive) {
        return;
    }
    _player->setSource(source);
    _player->play();
}

void HTIVoiceManager::_playSequence(const QList<QUrl>& sources, Priority priority)
{
    if (!_enabled || !_audioPackAvailable || (!_vietnameseUiActive && !_englishUiActive)) {
        return;
    }

    if (_sequenceActive && priority != Critical) {
        for (const QUrl& source : sources) {
            if (!source.isEmpty()) {
                _audioQueue.enqueue(source);
            }
        }
        return;
    }

    if (_player->playbackState() == QMediaPlayer::PlayingState) {
        if (priority != Critical) {
            return;
        }
        _audioQueue.clear();
        _sequenceActive = false;
        _player->stop();
    } else if (_sequenceActive) {
        _audioQueue.clear();
        _sequenceActive = false;
    } else {
        _audioQueue.clear();
    }

    for (const QUrl& source : sources) {
        if (!source.isEmpty()) {
            _audioQueue.enqueue(source);
        }
    }
    if (_audioQueue.isEmpty()) {
        return;
    }

    _sequenceActive = true;
    _playNextAudioSegment();
}

void HTIVoiceManager::_playNextAudioSegment()
{
    if (!_sequenceActive || _player->playbackState() == QMediaPlayer::PlayingState) {
        return;
    }
    if (_audioQueue.isEmpty()) {
        _sequenceActive = false;
        return;
    }

    _player->setSource(_audioQueue.dequeue());
    _player->play();
}

void HTIVoiceManager::speakEvent(const QString& event, int priority, const QString& detail)
{
    if (!_groupAllows(event)) {
        return;
    }
    const QUrl source = _audioSource(event, detail);
    if (source.isEmpty()) {
        return;
    }
    const int cooldown = priority >= Critical ? 2500 : 7000;
    if (_cooldownAllows(event + source.fileName(), cooldown)) {
        _play(source, static_cast<Priority>(qBound(0, priority, 2)));
    }
}

void HTIVoiceManager::_handleStatusText(const QString& text)
{
    struct StatusTextRule
    {
        const char* primary;
        const char* secondary;
        const char* event;
        Priority priority;
    };

    static const std::array<StatusTextRule, 36> statusTextRules = {{
        {"communication lost", "telemetry lost", "telemetry-lost", Warning},
        {"communication regained", "telemetry restored", "telemetry-restored", Info},
        {"signal weak", nullptr, "link-weak", Warning},
        {"signal recovered", nullptr, "link-recovered", Info},
        {"emergency land", nullptr, "emergency-land", Critical},
        {"takeoff complete", nullptr, "takeoff-complete", Info},
        {"takeoff", nullptr, "takeoff-started", Info},
        {"land complete", nullptr, "landing-complete", Info},
        {"landing", nullptr, "landing-started", Warning},
        {"home reached", "reached home", "home-reached", Info},
        {"mode change failed", nullptr, "mode-change-failed", Warning},
        {"mission upload failed", nullptr, "mission-upload-failed", Warning},
        {"mission upload", "mission received", "mission-upload-success", Info},
        {"mission complete", "mission finished", "mission-complete", Info},
        {"mission paused", nullptr, "mission-paused", Info},
        {"mission resumed", nullptr, "mission-resumed", Info},
        {"mission aborted", nullptr, "mission-aborted", Warning},
        {"mission started", nullptr, "mission-started", Info},
        {"waypoint reached", "reached command", "waypoint-reached", Info},
        {"rtk fixed", nullptr, "rtk-fixed", Info},
        {"rtk float", nullptr, "rtk-float", Info},
        {"gps acquiring", nullptr, "gps-acquiring", Info},
        {"gps lost", "no gps", "gps-lost", Warning},
        {"jamming", nullptr, "gps-jamming", Warning},
        {"spoofing", nullptr, "gps-spoofing", Critical},
        {"battery missing", nullptr, "battery-missing", Warning},
        {"battery error", nullptr, "battery-error", Critical},
        {"failsafe", nullptr, "failsafe", Critical},
        {"fence breached", "geofence breached", "geofence-breach", Critical},
        {"obstacle", nullptr, "obstacle-detected", Warning},
        {"ekf error", nullptr, "ekf-error", Critical},
        {"compass calibration", nullptr, "compass-calibration", Warning},
        {"home set", nullptr, "home-set", Info},
        {"recording started", nullptr, "recording-started", Info},
        {"recording stopped", nullptr, "recording-stopped", Info},
        {"photo captured", "camera photo", "camera-photo", Info},
    }};

    const QString lower = text.toLower();
    if (lower.startsWith(QStringLiteral("prearm"))) {
        speakEvent(QStringLiteral("prearm"), Critical, text);
        return;
    }

    for (const StatusTextRule& rule : statusTextRules) {
        const bool hasPrimaryMatch = lower.contains(QString::fromLatin1(rule.primary));
        const bool hasSecondaryMatch = rule.secondary != nullptr && lower.contains(QString::fromLatin1(rule.secondary));
        if (hasPrimaryMatch || hasSecondaryMatch) {
            speakEvent(QString::fromLatin1(rule.event), rule.priority);
            return;
        }
    }
}

void HTIVoiceManager::_vehicleAdded(Vehicle* vehicle)
{
    if (vehicle == nullptr) {
        return;
    }
    connect(vehicle, &Vehicle::armedChanged, this, [this](bool armed) {
        if (armed) {
            _resetDynamicAnnouncementState();
        } else {
            _audioQueue.clear();
            _sequenceActive = false;
            _player->stop();
            _resetDynamicAnnouncementState();
        }
        speakEvent(armed ? QStringLiteral("armed") : QStringLiteral("disarmed"), Info);
    });
    connect(vehicle, &Vehicle::flightModeChanged, this, [this](const QString& mode) {
        const QString lower = mode.toLower();
        if (lower == QStringLiteral("rtl") || lower.contains(QStringLiteral("return"))) {
            speakEvent(QStringLiteral("rtl"), Warning);
        } else if (lower == QStringLiteral("loiter") || lower == QStringLiteral("qloiter")) {
            speakEvent(QStringLiteral("loiter"), Info);
        } else if (lower == QStringLiteral("auto") || lower.contains(QStringLiteral("mission"))) {
            speakEvent(QStringLiteral("auto"), Info);
        } else if (lower.contains(QStringLiteral("guided"))) {
            speakEvent(QStringLiteral("guided"), Info);
        } else if (lower.contains(QStringLiteral("stabilize"))) {
            speakEvent(QStringLiteral("stabilize"), Info);
        } else if (lower.contains(QStringLiteral("altitude"))) {
            speakEvent(QStringLiteral("altitude-hold"), Info);
        } else if (lower.contains(QStringLiteral("position"))) {
            speakEvent(QStringLiteral("position-hold"), Info);
        } else if (lower.contains(QStringLiteral("manual"))) {
            speakEvent(QStringLiteral("manual"), Info);
        }
    });
    connect(vehicle, &Vehicle::flyingChanged, this, [this](bool flying) {
        speakEvent(flying ? QStringLiteral("takeoff-started") : QStringLiteral("landing-complete"), Info);
    });
    connect(vehicle, &Vehicle::landingChanged, this, [this](bool landing) {
        if (landing) {
            speakEvent(QStringLiteral("landing-started"), Warning);
        }
    });
    connect(vehicle, &Vehicle::prearmErrorChanged, this, [this](const QString& error) {
        if (!error.isEmpty()) {
            speakEvent(QStringLiteral("prearm"), Critical, error);
        }
    });
    connect(vehicle, &Vehicle::textMessageReceived, this,
            [this](int, int, int, const QString& text, const QString&) { _handleStatusText(text); });
    speakEvent(QStringLiteral("connected"), Info);
}

void HTIVoiceManager::_vehicleRemoved(Vehicle* vehicle)
{
    if (vehicle == _vehicle) {
        _vehicle = nullptr;
    }
    speakEvent(QStringLiteral("disconnected"), Warning);
}

void HTIVoiceManager::_activeVehicleChanged(Vehicle* vehicle)
{
    _vehicle = vehicle;
    _lastGpsLock = -1;
    _lastGpsJammingState = -1;
    _lastGpsSpoofingState = -1;
    _lastBatteryPercent = -1;
    _lastBatteryVoicePercent = -1.0;
    _lastHomeDistanceAnnouncementStep = -1;
    _lastHomeDistanceBelowOneKmStep = -1;
    _nextTotalDistanceAnnouncementMeters = TotalDistanceAnnouncementIntervalMeters;
    _lastAltitudeAnnouncementStep = -1;
    _lastAltitudeBelowFiftyMetersStep = -1;
    _hasAnnouncedAltitudeBelowOneMeter = false;
    _lastRelativeAltitudeMeters = -1.0;
    if (_vehicle != nullptr && _vehicle->armed()) {
        _resetDynamicAnnouncementState();
    }
}

void HTIVoiceManager::_pollVehicleState()
{
    if (_vehicle == nullptr) {
        return;
    }

    FactGroup* gpsFacts = _vehicle->gpsFactGroup();
    if (gpsFacts != nullptr && gpsFacts->factExists(QStringLiteral("lock"))) {
        const Fact* lockFact = gpsFacts->getFact(QStringLiteral("lock"));
        if (lockFact == nullptr) {
            return;
        }

        const int lock = lockFact->rawValue().toInt();
        if (_lastGpsLock >= 0 && lock >= 3 && _lastGpsLock < 3) {
            speakEvent(QStringLiteral("gps-ready"), Info);
        }
        if (_lastGpsLock >= 3 && lock < 3) {
            speakEvent(QStringLiteral("gps-degraded"), Warning);
        }
        if (_lastGpsLock < 0 && lock < 3) {
            speakEvent(QStringLiteral("gps-acquiring"), Info);
        }
        _lastGpsLock = lock;

        if (gpsFacts->factExists(QStringLiteral("jammingState"))) {
            const Fact* jammingFact = gpsFacts->getFact(QStringLiteral("jammingState"));
            if (jammingFact != nullptr) {
                const int jammingState = jammingFact->rawValue().toInt();
                if (_lastGpsJammingState >= 0 && jammingState > 0 && jammingState < 255 &&
                    (_lastGpsJammingState == 0 || _lastGpsJammingState == 255)) {
                    speakEvent(QStringLiteral("gps-jamming"), Warning);
                }
                _lastGpsJammingState = jammingState;
            }
        }
        if (gpsFacts->factExists(QStringLiteral("spoofingState"))) {
            const Fact* spoofingFact = gpsFacts->getFact(QStringLiteral("spoofingState"));
            if (spoofingFact != nullptr) {
                const int spoofingState = spoofingFact->rawValue().toInt();
                if (_lastGpsSpoofingState >= 0 && spoofingState > 0 && spoofingState < 255 &&
                    (_lastGpsSpoofingState == 0 || _lastGpsSpoofingState == 255)) {
                    speakEvent(QStringLiteral("gps-spoofing"), Critical);
                }
                _lastGpsSpoofingState = spoofingState;
            }
        }
    }

    QmlObjectListModel* batteries = _vehicle->batteries();
    if (batteries != nullptr && batteries->count() > 0) {
        BatteryFactGroup* battery = qobject_cast<BatteryFactGroup*>(batteries->get(0));
        if (battery != nullptr) {
            const double percent = battery->percentRemaining()->rawValue().toDouble();
            if (qIsFinite(percent)) {
                if (_lastBatteryVoicePercent < 0.0 || percent > _lastBatteryVoicePercent) {
                    _lastBatteryVoicePercent = percent;
                } else if (percent <= _lastBatteryVoicePercent - 5.0) {
                    if (_batteryAlerts) {
                        _announceBattery(qBound(0, qFloor(percent), 100));
                    }
                    _lastBatteryVoicePercent = percent;
                }

                if (_lastBatteryPercent >= 0 && percent <= 10 && _lastBatteryPercent > 10) {
                    speakEvent(QStringLiteral("battery-10"), Critical);
                } else if (_lastBatteryPercent >= 0 && percent <= 20 && _lastBatteryPercent > 20) {
                    speakEvent(QStringLiteral("battery-20"), Warning);
                } else if (_lastBatteryPercent >= 0 && percent <= 25 && _lastBatteryPercent > 25) {
                    speakEvent(QStringLiteral("battery-low"), Warning);
                } else if (_lastBatteryPercent >= 0 && percent <= 30 && _lastBatteryPercent > 30) {
                    speakEvent(QStringLiteral("battery-30"), Info);
                }
                _lastBatteryPercent = percent;
            }
        }
    } else if (_lastBatteryPercent >= 0) {
        _lastBatteryPercent = -1;
        _lastBatteryVoicePercent = -1.0;
        speakEvent(QStringLiteral("battery-missing"), Warning);
    }

    if (!_vehicle->armed()) {
        return;
    }

    FactGroup* vehicleFacts = _vehicle->vehicleFactGroup();
    if (vehicleFacts == nullptr) {
        return;
    }

    const Fact* distanceFact = vehicleFacts->getFact(QStringLiteral("flightDistance"));
    const Fact* distanceToHomeFact = vehicleFacts->getFact(QStringLiteral("distanceToHome"));
    const Fact* altitudeFact = vehicleFacts->getFact(QStringLiteral("altitudeRelative"));
    if (distanceFact == nullptr || altitudeFact == nullptr) {
        return;
    }

    const double distance = distanceFact->rawValue().toDouble();
    if (distanceToHomeFact != nullptr) {
        const double distanceToHome = distanceToHomeFact->rawValue().toDouble();
        if (qIsFinite(distanceToHome)) {
            if (distanceToHome >= 1000.0) {
                _lastHomeDistanceBelowOneKmStep = -1;
                const int homeDistanceStep = qFloor(distanceToHome / 1000.0);
                if (_lastHomeDistanceAnnouncementStep < 0) {
                    _lastHomeDistanceAnnouncementStep = homeDistanceStep;
                    _announceDistanceToHome(distanceToHome);
                } else if (homeDistanceStep != _lastHomeDistanceAnnouncementStep) {
                    _announceDistanceToHome(distanceToHome);
                    _lastHomeDistanceAnnouncementStep = homeDistanceStep;
                }
            } else {
                const int homeDistanceStep = qMax(0, qFloor(distanceToHome / 100.0));
                const bool crossedBelowOneKm = _lastHomeDistanceAnnouncementStep > 0;
                _lastHomeDistanceAnnouncementStep = -1;
                if (crossedBelowOneKm) {
                    _announceDistanceToHome(distanceToHome);
                }

                if (_lastHomeDistanceBelowOneKmStep < 0) {
                    _lastHomeDistanceBelowOneKmStep = homeDistanceStep;
                } else if (homeDistanceStep < _lastHomeDistanceBelowOneKmStep) {
                    _announceDistanceToHome(distanceToHome);
                    _lastHomeDistanceBelowOneKmStep = homeDistanceStep;
                } else if (homeDistanceStep > _lastHomeDistanceBelowOneKmStep) {
                    _lastHomeDistanceBelowOneKmStep = homeDistanceStep;
                }
            }
        }
    }

    if (qIsFinite(distance) && distance >= _nextTotalDistanceAnnouncementMeters) {
        _announceTotalDistance(distance);
        _nextTotalDistanceAnnouncementMeters = (std::floor(distance / TotalDistanceAnnouncementIntervalMeters) + 1.0) *
                                               TotalDistanceAnnouncementIntervalMeters;
    }

    const double altitude = altitudeFact->rawValue().toDouble();
    if (qIsFinite(altitude)) {
        bool altitudeAnnounced = false;
        if (altitude >= 1.0) {
            _hasAnnouncedAltitudeBelowOneMeter = false;
        }
        if (altitude > 0.0) {
            const int altitudeStep = qFloor(altitude / 100.0);
            if (_lastAltitudeAnnouncementStep < 0) {
                _lastAltitudeAnnouncementStep = altitudeStep;
                if (altitudeStep > 0) {
                    _announceAltitude(altitude);
                    altitudeAnnounced = true;
                }
            } else if (altitudeStep != _lastAltitudeAnnouncementStep) {
                _announceAltitude(altitude);
                altitudeAnnounced = true;
                _lastAltitudeAnnouncementStep = altitudeStep;
            }
        } else {
            _lastAltitudeAnnouncementStep = 0;
        }

        if (altitude >= LowAltitudeAnnouncementStartMeters || altitude <= 0.0) {
            _lastAltitudeBelowFiftyMetersStep = -1;
        } else {
            const int altitudeStep = qMax(0, qFloor(altitude / LowAltitudeAnnouncementIntervalMeters));
            const bool crossedBelowFiftyMeters = _lastRelativeAltitudeMeters >= LowAltitudeAnnouncementStartMeters;
            if (_lastAltitudeBelowFiftyMetersStep < 0) {
                _lastAltitudeBelowFiftyMetersStep = altitudeStep;
                if (crossedBelowFiftyMeters) {
                    _announceAltitude(altitude);
                    altitudeAnnounced = true;
                }
            } else if (altitudeStep < _lastAltitudeBelowFiftyMetersStep) {
                _announceAltitude(altitude);
                altitudeAnnounced = true;
                _lastAltitudeBelowFiftyMetersStep = altitudeStep;
            } else if (altitudeStep > _lastAltitudeBelowFiftyMetersStep) {
                _lastAltitudeBelowFiftyMetersStep = altitudeStep;
            }

            if (altitude < 1.0) {
                if (altitudeAnnounced) {
                    _hasAnnouncedAltitudeBelowOneMeter = true;
                } else if (!_hasAnnouncedAltitudeBelowOneMeter &&
                           _player->playbackState() != QMediaPlayer::PlayingState && !_sequenceActive) {
                    _announceAltitude(altitude);
                    _hasAnnouncedAltitudeBelowOneMeter = true;
                }
            } else if (altitude < LowAltitudeAnnouncementIntervalMeters && !altitudeAnnounced &&
                       _player->playbackState() != QMediaPlayer::PlayingState && !_sequenceActive) {
                _announceAltitude(altitude);
            }
        }
        _lastRelativeAltitudeMeters = altitude;
    } else {
        _lastAltitudeBelowFiftyMetersStep = -1;
        _hasAnnouncedAltitudeBelowOneMeter = false;
        _lastRelativeAltitudeMeters = -1.0;
    }
}
