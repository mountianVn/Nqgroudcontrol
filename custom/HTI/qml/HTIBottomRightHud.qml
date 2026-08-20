import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

// Compact telemetry overlay for the bottom-right of Fly View.
Item {
    id: root

    readonly property var _vehicle: QGroundControl.multiVehicleManager
        ? QGroundControl.multiVehicleManager.activeVehicle
        : null
    readonly property bool _hasVehicle: !!_vehicle

    readonly property real _spacing:         10 // Khoảng cách giữa các cụm gauge; dùng 8-12 để cân bố cục.
    readonly property real _rowGap:           6
    readonly property real _pillWidth:       92
    readonly property real _wpPillWidth:     108
    readonly property real _preferredWidth:   484 // Thêm chỗ cho Attitude và Heading lớn hơn mà không bị cắt.
    readonly property real _horizontalMargin: ScreenTools.defaultFontPixelWidth
    readonly property real _availableWidth:   parent ? Math.max(0, parent.width - _horizontalMargin * 2) : _preferredWidth
    readonly property real _gaugeSize:        Math.max(40, Math.min(104, (width - _spacing * 2) / 4.9)) // Size gauge cơ sở.

    // Vehicle Fact values. Invalid telemetry is normalized at this boundary so
    // individual widgets never need to handle NaN or a missing Fact object.
    readonly property real _flightTime:       _factValue(_vehicle ? _vehicle.flightTime : null)
    readonly property real _homeDistance:     _factValue(_vehicle ? _vehicle.distanceToHome : null)
    readonly property real _totalDistance:    _factValue(_vehicle ? _vehicle.flightDistance : null)
    readonly property real _distanceToNextWP: _factValue(_vehicle ? _vehicle.distanceToNextWP : null)
    readonly property int  _currentWP:        Math.max(0, Math.round(_factValue(_vehicle ? _vehicle.missionItemIndex : null)))
    readonly property real _altitude:         _factValue(_vehicle ? _vehicle.altitudeRelative : null)
    readonly property real _climbRate:        _factValue(_vehicle ? _vehicle.climbRate : null)
    readonly property real _groundSpeed:      _factValue(_vehicle ? _vehicle.groundSpeed : null)
    readonly property real _roll:             _factValue(_vehicle ? _vehicle.roll : null)
    readonly property real _pitch:            _factValue(_vehicle ? _vehicle.pitch : null)
    readonly property real _heading:          _factValue(_vehicle ? _vehicle.heading : null)

    width: Math.min(_preferredWidth, _availableWidth)
    implicitHeight: mainLayout.implicitHeight
    height: implicitHeight

    function _factValue(fact, fallback = 0) {
        if (!fact || typeof fact.rawValue === "undefined") {
            return fallback
        }

        var value = Number(fact.rawValue)
        return isFinite(value) ? value : fallback
    }

    function formatTime(seconds) {
        var totalSeconds = Math.max(0, Math.floor(Number(seconds) || 0))
        var hours = Math.floor(totalSeconds / 3600)
        var minutes = Math.floor((totalSeconds % 3600) / 60)
        var remainingSeconds = totalSeconds % 60
        return String(hours).padStart(2, "0") + ":" +
               String(minutes).padStart(2, "0") + ":" +
               String(remainingSeconds).padStart(2, "0")
    }

    function formatDistance(meters) {
        var value = Number(meters)
        if (!isFinite(value) || value <= 0) {
            return "0 m"
        }
        return value >= 1000 ? (value / 1000).toFixed(1) + " km" : value.toFixed(0) + " m"
    }

    ColumnLayout {
        id:             mainLayout
        anchors.fill:   parent
        spacing:        root._rowGap

        RowLayout {
            Layout.fillWidth: true
            spacing:          root._spacing

            HTIInfoPill {
                Layout.fillWidth: true
                Layout.preferredWidth: root._pillWidth
                label:             qsTr("Time")
                value:             root.formatTime(root._flightTime)
                iconSource:        "/InstrumentValueIcons/time.svg"
                bgColor:           "#ec9800"
            }

            HTIInfoPill {
                Layout.fillWidth: true
                Layout.preferredWidth: root._pillWidth
                label:             qsTr("Home")
                value:             root.formatDistance(root._homeDistance)
                iconSource:        "/InstrumentValueIcons/home.svg"
                bgColor:           "#235fc2"
            }

            HTIInfoPill {
                Layout.fillWidth: true
                Layout.preferredWidth: root._pillWidth
                label:             qsTr("Total")
                value:             root.formatDistance(root._totalDistance)
                iconSource:        "/InstrumentValueIcons/target.svg"
                bgColor:           "#319748"
            }

            HTIInfoPill {
                Layout.fillWidth: true
                Layout.preferredWidth: root._wpPillWidth
                label:             qsTr("WP #%1").arg(root._currentWP)
                value:             root.formatDistance(root._distanceToNextWP)
                iconSource:        "/res/waypoint.svg"
                bgColor:           "#71787d"
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            spacing:          root._spacing

            HTISpeedAltitudeGauge {
                Layout.preferredWidth:  root._gaugeSize * 2.9 // Cụm Speed+Altitude rộng hơn Attitude/Heading.
                Layout.preferredHeight: root._gaugeSize * 1.45 // Chiều cao cụm kết hợp; giữ tỷ lệ background 2:1.
                size:                   root._gaugeSize * 1.45 // Size truyền vào component Speed+Altitude.
                hasVehicle:             root._hasVehicle
                altitude:               root._altitude
                climbRate:              root._climbRate
                groundSpeed:            root._groundSpeed
            }

            HTIAttitudeGauge {
                Layout.preferredWidth:  root._gaugeSize * 1.12
                Layout.preferredHeight: root._gaugeSize * 1.12
                size:                   root._gaugeSize * 1.12 // Phóng riêng Attitude lớn hơn khoảng 12%.
                hasVehicle:             root._hasVehicle
                roll:                   root._roll
                pitch:                  root._pitch
            }

            HTIHeadingGauge {
                Layout.preferredWidth:  root._gaugeSize * 1.12
                Layout.preferredHeight: root._gaugeSize * 1.12
                size:                   root._gaugeSize * 1.12 // Phóng riêng Heading lớn hơn khoảng 12%.
                hasVehicle:             root._hasVehicle
                heading:               root._heading
            }
        }
    }
}
