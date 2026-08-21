import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool showPreFlightStatus: false
    property string actionMessage: ""
    property string _mavlinkLogHistory: ""

    // 0.25 là khoảng đệm dưới cùng; tăng nếu nội dung sát đáy panel.
    implicitHeight: contentColumn.y + contentColumn.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.25

    // Vehicle exposes orbit radius only as part of a guided orbit command. Keep
    // this hook explicit so a future orbit editor can connect it without fake state.
    signal setRadiusRequested(real radius)

    readonly property var _battery: activeVehicle && activeVehicle.batteries && activeVehicle.batteries.count > 0 ? activeVehicle.batteries.get(0) : null
    readonly property real _batteryPercent: _factValue(_battery ? _battery.percentRemaining : null, 0)

    function _syncMavlinkLogHistory() {
        root._mavlinkLogHistory = root.activeVehicle ? String(root.activeVehicle.formattedMessages || "") : ""
    }

    onActiveVehicleChanged: root._syncMavlinkLogHistory()

    Connections {
        target: root.activeVehicle

        function onNewFormattedMessage(formattedMessage) {
            root._mavlinkLogHistory = String(formattedMessage || "") + root._mavlinkLogHistory
        }
    }

    function _factValue(fact, fallback) {
        if (!fact || typeof fact.rawValue === "undefined") {
            return fallback
        }
        const value = Number(fact.rawValue)
        return isFinite(value) ? value : fallback
    }

    function _validNumber(text) {
        const value = Number(text)
        return text !== "" && isFinite(value)
    }

    function _setFlightMode(preferredMode) {
        if (!root.activeVehicle || !root.activeVehicle.flightModeSetAvailable) {
            return
        }

        let mode = preferredMode || ""
        const modes = root.activeVehicle.flightModes || []
        for (let i = 0; i < modes.length; i++) {
            if (String(modes[i]).toLowerCase() === String(preferredMode).toLowerCase()) {
                mode = modes[i]
                break
            }
        }
        if (mode !== "") {
            root.activeVehicle.flightMode = mode
        }
    }

    function _isModeActive(preferredMode) {
        if (!root.activeVehicle || !preferredMode) {
            return false
        }
        return String(root.activeVehicle.flightMode || "").toLowerCase() === String(preferredMode).toLowerCase()
    }

    function _startMission() {
        if (!root.activeVehicle) {
            return
        }
        // FirmwarePlugin::startMission selects the firmware-specific mission mode and starts it.
        root.activeVehicle.startMission()
    }

    function _setWaypoint() {
        if (root.activeVehicle && _validNumber(wpSelector.currentText)) {
            root.activeVehicle.setCurrentMissionSequence(Math.max(0, Math.floor(Number(wpSelector.currentText))))
        }
    }

    function _setAltitude() {
        if (!root.activeVehicle || !_validNumber(altitudeField.text)) {
            return
        }
        const targetAltitude = Number(altitudeField.text)
        const currentAltitude = _factValue(root.activeVehicle.vehicle.altitudeRelative, 0)
        root.activeVehicle.guidedModeChangeAltitude(targetAltitude - currentAltitude, false)
    }

    function _setActionMessage(message) {
        root.actionMessage = message
    }

    function _formatCoordinate(value) {
        return isFinite(Number(value)) ? Number(value).toFixed(6) : qsTr("N/A")
    }

    function _formatSpeed(fact) {
        if (!root.activeVehicle) {
            return qsTr("0 km/h")
        }
        return qsTr("%1 km/h").arg(Math.max(0, Math.round(_factValue(fact, 0) * 3.6)))
    }

    function _formatSignal() {
        if (!root.activeVehicle) {
            return qsTr("--")
        }
        const signal = _factValue(root.activeVehicle.radioStatus ? root.activeVehicle.radioStatus.lrssi : null, 0)
        return qsTr("%1 dBm").arg(Math.round(signal))
    }

    function _formatRemainingTime() {
        if (!_battery || !_battery.timeRemainingStr || !_battery.timeRemaining ||
                !isFinite(Number(_battery.timeRemaining.rawValue))) {
            return qsTr("--:-- minute(s)")
        }
        const value = String(_battery.timeRemainingStr.rawValue || "")
        return value === "" ? qsTr("--:-- minute(s)") : value
    }

    function _messageText() {
        if (!root.activeVehicle) {
            return qsTr("No Messages")
        }
        if (root.activeVehicle.prearmError && root.activeVehicle.prearmError !== "") {
            return root._translateMavlinkText(root.activeVehicle.prearmError)
        }
        if (!root.activeVehicle.allSensorsHealthy) {
            return qsTr("Sensor health warning")
        }
        return qsTr("No Messages")
    }

    // MAVLink STATUS_TEXT is firmware-generated, so translate recognized templates
    // while preserving dynamic sensor ids, channel ranges, and sampling values.
    function _translateMavlinkText(text) {
        let translated = String(text || "")
        translated = translated.replace(/PreArm: Battery (\d+) below minimum arming voltage/g,
            function(match, battery) { return qsTr("PreArm: Battery %1 below minimum arming voltage").arg(battery) })
        translated = translated.replace(/PreArm: Compass (\d+) not healthy/g,
            function(match, compass) { return qsTr("PreArm: Compass %1 not healthy").arg(compass) })
        translated = translated.replace(/PreArm: Gyros inconsistent/g, qsTr("PreArm: Gyros inconsistent"))
        translated = translated.replace(/PreArm: RC not found/g, qsTr("PreArm: RC not found"))
        translated = translated.replace(/EKF(\d+) IMU(\d+) tilt alignment complete/g,
            function(match, ekf, imu) { return qsTr("EKF%1 IMU%2 tilt alignment complete").arg(ekf).arg(imu) })
        translated = translated.replace(/AHRS: EKF(\d+) active/g,
            function(match, ekf) { return qsTr("AHRS: EKF%1 active").arg(ekf) })
        translated = translated.replace(/EKF(\d+) IMU(\d+) initialised/g,
            function(match, ekf, imu) { return qsTr("EKF%1 IMU%2 initialised").arg(ekf).arg(imu) })
        translated = translated.replace(/RCOut: PWM:(\d+)-(\d+)/g,
            function(match, first, last) { return qsTr("RCOut: PWM:%1-%2").arg(first).arg(last) })
        translated = translated.replace(/AHRS: DCM active/g, qsTr("AHRS: DCM active"))
        translated = translated.replace(/ArduPilot Ready/g, qsTr("ArduPilot Ready"))
        translated = translated.replace(/Initialising ArduPilot/g, qsTr("Initialising ArduPilot"))
        translated = translated.replace(/Frame: ([^<\r\n]+)/g,
            function(match, frame) { return qsTr("Frame: %1").arg(frame) })
        translated = translated.replace(/IMU(\d+): normal sampling ([^<\r\n]+)/g,
            function(match, imu, rate) { return qsTr("IMU%1: normal sampling %2").arg(imu).arg(rate) })
        translated = translated.replace(/IMU(\d+): fast sampling ([^<\r\n]+)/g,
            function(match, imu, rate) { return qsTr("IMU%1: fast sampling %2").arg(imu).arg(rate) })
        translated = translated.replace(/RCOut: Initialising/g, qsTr("RCOut: Initialising"))
        translated = translated.replace(/Barometer (\d+) calibration complete/g,
            function(match, barometer) { return qsTr("Barometer %1 calibration complete").arg(barometer) })
        translated = translated.replace(/Calibrating barometer/g, qsTr("Calibrating barometer"))
        return translated
    }

    function _formatLogMessage(message) {
        let formatted = root._translateMavlinkText(message)

        formatted = formatted.replace(new RegExp("<#E>", "g"), "color: #FF5A52; font: 10pt monospace;")
        formatted = formatted.replace(new RegExp("<#I>", "g"), "color: #F4D35E; font: 10pt monospace;")
        formatted = formatted.replace(new RegExp("<#N>", "g"), "color: #EAF6FF; font: 10pt monospace;")
        return formatted
    }

    function _allMessagesText() {
        if (root._mavlinkLogHistory !== "") {
            return root._formatLogMessage(root._mavlinkLogHistory)
        }
        return root._messageText()
    }

    Component.onCompleted: root._syncMavlinkLogHistory()

    Popup {
        id: logPopup

        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Math.min(parent.width * 0.72, ScreenTools.defaultFontPixelWidth * 92)
        height: Math.min(parent.height * 0.76, ScreenTools.defaultFontPixelHeight * 34)
        modal: true
        focus: true
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        onOpened: {
            fullLogText.cursorPosition = 0
            fullLogText.forceActiveFocus()
        }

        background: Rectangle {
            radius: 18
            color: "#F208111A"
            border.width: 1.5
            border.color: "#31C8FF"
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1.4
            spacing: ScreenTools.defaultFontPixelHeight * 0.65

            RowLayout {
                Layout.fillWidth: true

                QGCLabel {
                    Layout.fillWidth: true
                    text: qsTr("Vehicle Messages")
                    color: "#63F29A"
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.weight: Font.DemiBold
                }

                HTIModernButton {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 9
                    text: qsTr("Close")
                    variant: "secondary"
                    compact: true
                    onClicked: logPopup.close()
                }
            }

            ScrollView {
                id: logScrollView

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                TextArea {
                    id: fullLogText

                    width: logScrollView.availableWidth
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    textFormat: TextEdit.RichText
                    text: root._allMessagesText()
                    color: "#EAF6FF"
                    font.family: "monospace"
                    font.pointSize: ScreenTools.smallFontPointSize + 1
                    padding: ScreenTools.defaultFontPixelWidth

                    background: Rectangle {
                        radius: 14
                        color: "#D90B1520"
                        border.width: 1
                        border.color: "#315F72"
                    }
                }
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.6
        contentY: 0 // Khóa nội dung ở đầu panel, không dịch chuyển khi lăn chuột.
        interactive: false // Tắt kéo/cuộn bằng chuột và cảm ứng để panel luôn cố định.
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn
            x: ScreenTools.defaultFontPixelWidth * 0.5
            y: ScreenTools.defaultFontPixelHeight * 0.25
            width: flick.width - ScreenTools.defaultFontPixelWidth
            spacing: ScreenTools.defaultFontPixelHeight * 0.3

            HTIModernButton {
                Layout.fillWidth: true
                text: qsTr("Start Mission - Auto Mode")
                variant: "primary"
                enabled: !!root.activeVehicle
                onClicked: root._startMission()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth * 0.35

                HTIModernButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
                    text: qsTr("Auto")
                    variant: "primary"
                    active: root._isModeActive(root.activeVehicle ? root.activeVehicle.missionFlightMode : "")
                    enabled: !!root.activeVehicle
                    onClicked: root._setFlightMode(root.activeVehicle ? root.activeVehicle.missionFlightMode : "")
                }

                HTIModernButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
                    text: qsTr("Set WP")
                    variant: "secondary"
                    compact: true
                    enabled: !!root.activeVehicle
                    onClicked: root._setWaypoint()
                }

                QGCComboBox {
                    id: wpSelector
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 5
                    Layout.preferredHeight: 34
                    model: ["0", "1", "2", "3", "4"]
                    currentIndex: 0
                    sizeToContents: false
                    contentItem: QGCLabel {
                        text: wpSelector.currentText
                        color: "#F4F8FB"
                        font: wpSelector.font
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    indicator: QGCColoredImage {
                        anchors.right: parent.right
                        anchors.rightMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 10
                        source: "/qmlimages/arrow-down.png"
                        color: "#F4F8FB"
                    }
                    background: Rectangle {
                        radius: 8.8
                        color: wpSelector.pressed ? "#0D1722" : "#111A22"
                        border.width: wpSelector.activeFocus ? 2 : 1.5
                        border.color: wpSelector.activeFocus ? "#63F29A" : "#35D7FF"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth * 0.35

                HTIModernButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
                    text: qsTr("Loiter")
                    variant: "primary"
                    active: root._isModeActive("Loiter")
                    enabled: !!root.activeVehicle
                    onClicked: root._setFlightMode("Loiter")
                }

                HTIModernButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
                    text: qsTr("Set Radius")
                    variant: "secondary"
                    compact: true
                    enabled: root._validNumber(radiusField.text)
                    onClicked: root.setRadiusRequested(Number(radiusField.text))
                }

                QGCTextField {
                    id: radiusField
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 5
                    Layout.preferredHeight: 34
                    text: "370"
                    numericValuesOnly: true
                    horizontalAlignment: Text.AlignRight
                    color: "#F4F8FB"
                    background: Rectangle {
                        radius: 8.8
                        color: "#111A22"
                        border.width: radiusField.activeFocus ? 2 : 1.5
                        border.color: radiusField.activeFocus ? "#63F29A" : "#35D7FF"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth * 0.35

                HTIModernButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
                    text: qsTr("QLoiter")
                    variant: "primary"
                    active: root._isModeActive("QLoiter")
                    enabled: !!root.activeVehicle
                    onClicked: root._setFlightMode("QLoiter")
                }

                HTIModernButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
                    text: qsTr("Set Altitude")
                    variant: "secondary"
                    compact: true
                    enabled: !!root.activeVehicle && root._validNumber(altitudeField.text)
                    onClicked: root._setAltitude()
                }

                QGCTextField {
                    id: altitudeField
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 5
                    Layout.preferredHeight: 34
                    text: "100"
                    numericValuesOnly: true
                    horizontalAlignment: Text.AlignRight
                    color: "#F4F8FB"
                    background: Rectangle {
                        radius: 8.8
                        color: "#111A22"
                        border.width: altitudeField.activeFocus ? 2 : 1.5
                        border.color: altitudeField.activeFocus ? "#63F29A" : "#35D7FF"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth * 0.5

                HTIModernButton {
                    Layout.fillWidth: true
                    text: qsTr("Return To Home")
                    variant: "blue"
                    enabled: !!root.activeVehicle
                    onClicked: {
                        if (root.activeVehicle) {
                            root.activeVehicle.guidedModeRTL(false)
                        }
                    }
                }

                HTIModernButton {
                    Layout.fillWidth: true
                    text: qsTr("Emergency Landing")
                    variant: "danger"
                    enabled: !!root.activeVehicle
                    onClicked: {
                        if (root.activeVehicle) {
                            root.activeVehicle.guidedModeLand()
                        }
                    }
                }
            }

            HTIModernButton {
                Layout.fillWidth: true
                text: qsTr("Pre-Flight Check")
                variant: "primary"
                active: root.showPreFlightStatus
                onClicked: root.showPreFlightStatus = !root.showPreFlightStatus
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: preflightColumn.implicitHeight + ScreenTools.defaultFontPixelHeight
                visible: root.showPreFlightStatus
                radius: 16
                color: "#B30D1722"
                border.color: "#2B7187"
                border.width: 1.5

                ColumnLayout {
                    id: preflightColumn
                    anchors.fill: parent
                    anchors.margins: ScreenTools.defaultFontPixelWidth * 0.7
                    spacing: 1

                    QGCLabel {
                        Layout.fillWidth: true
                        text: root.activeVehicle ? (root.activeVehicle.readyToFlyAvailable ?
                            (root.activeVehicle.readyToFly ? qsTr("Ready to fly") : qsTr("Not ready to fly")) :
                            (root.activeVehicle.allSensorsHealthy ? qsTr("Sensors healthy") : qsTr("Sensor health warning"))) : qsTr("No vehicle")
                        color: root.activeVehicle && root.activeVehicle.readyToFly ? "#75d18f" : "#f0c36a"
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    QGCLabel {
                        Layout.fillWidth: true
                        text: root.activeVehicle && root.activeVehicle.prearmError ? root.activeVehicle.prearmError : qsTr("No prearm message")
                        color: "#d7e0e8"
                        font.pointSize: ScreenTools.smallFontPointSize
                        wrapMode: Text.Wrap
                    }
                }
            }

            QGCLabel {
                Layout.fillWidth: true
                text: qsTr("Telemetry")
                color: "#63F29A"
                font.pointSize: ScreenTools.smallFontPointSize+1 // Cỡ chữ tiêu đề Telemetry.
                font.weight: Font.DemiBold
                topPadding: ScreenTools.defaultFontPixelHeight * 0.2 // Khoảng trống phía trên tiêu đề.
            }

            Rectangle {
                Layout.fillWidth: true
                // Chiều cao khung GPS = tổng chiều cao các hàng + phần đệm 1 dòng chữ.
                Layout.preferredHeight: gpsRows.implicitHeight + ScreenTools.defaultFontPixelHeight
                radius: 16 // Card GPS/speed kiểu glass.
                color: "#B30A1722"
                border.color: "#39D98A"
                border.width: 1.5

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScreenTools.defaultFontPixelWidth * 0.35 // Padding bên trong khung GPS.
                    spacing: ScreenTools.defaultFontPixelWidth * 0.35 // Khoảng cách giữa icon GPS và các hàng.

                    Item {
                        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6.5 // Chiều rộng vùng icon GPS.
                        Layout.fillHeight: true

                        QGCColoredImage {
                            anchors.centerIn: parent
                            width: ScreenTools.defaultFontPixelWidth * 5 // Kích thước icon GPS.
                            height: width
                            source: "/qmlimages/Gps.svg"
                            color: "#a9d5f3"
                            fillMode: Image.PreserveAspectFit
                            sourceSize.height: height
                        }
                    }

                    ColumnLayout {
                        id: gpsRows
                        Layout.fillWidth: true
                        spacing: 0 // Khoảng cách dọc giữa các hàng Telemetry.

                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("GPS Count"); value: root.activeVehicle ? String(Math.round(root._factValue(root.activeVehicle.gps ? root.activeVehicle.gps.count : null, 0))) : qsTr("N/A") }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Latitude"); value: root.activeVehicle ? root._formatCoordinate(root.activeVehicle.latitude) : qsTr("N/A") }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Longitude"); value: root.activeVehicle ? root._formatCoordinate(root.activeVehicle.longitude) : qsTr("N/A") }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Air Speed"); value: root._formatSpeed(root.activeVehicle ? root.activeVehicle.vehicle.airSpeed : null) }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Ground Speed"); value: root._formatSpeed(root.activeVehicle ? root.activeVehicle.vehicle.groundSpeed : null) }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Wind Speed"); value: root._formatSpeed(root.activeVehicle ? (root.activeVehicle.wind ? root.activeVehicle.wind.speed : null) : null) }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Signal"); value: root._formatSignal() }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#2C7188"
            }

            Rectangle {
                Layout.fillWidth: true
                // Chiều cao khung pin = tổng chiều cao các hàng + phần đệm 1 dòng chữ.
                Layout.preferredHeight: batteryRows.implicitHeight + ScreenTools.defaultFontPixelHeight
                radius: 16 // Card pin kiểu glass.
                color: "#B30D1722"
                border.color: "#6D8792"
                border.width: 1.5

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScreenTools.defaultFontPixelWidth * 0.35 // Padding bên trong khung Battery.
                    spacing: ScreenTools.defaultFontPixelWidth * 0.35 // Khoảng cách giữa icon và các hàng Battery.

                    Item {
                        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6.5 // Chiều rộng vùng icon máy bay/pin.
                        Layout.fillHeight: true



                        QGCColoredImage {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom

                            anchors.rightMargin: 4  // Tăng để dịch icon sang trái.
                            anchors.bottomMargin: 30 // Tăng để dịch icon lên trên.

                            width: ScreenTools.defaultFontPixelWidth * 5.5 // Kích thước icon pin nhỏ.
                            height: width
                            source: "/qmlimages/Battery.svg"
                            color: root._batteryPercent > 20 ? "#68d783" : "#eb5d5d"
                            fillMode: Image.PreserveAspectFit
                            sourceSize.height: height
                        }
                    }

                    ColumnLayout {
                        id: batteryRows
                        Layout.fillWidth: true
                        spacing: 0 // Khoảng cách dọc giữa các hàng Battery.

                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Battery Capacity"); value: qsTr("%1%").arg(Math.max(0, Math.min(100, Math.round(root._batteryPercent)))) }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Estimated Time"); value: root._formatRemainingTime() }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Battery Voltage"); value: qsTr("%1 V").arg(root._battery ? root._factValue(root._battery.voltage, 0).toFixed(1) : "0.0") }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Consumed"); value: qsTr("%1 mAh").arg(root._battery ? root._factValue(root._battery.mahConsumed, 0).toFixed(0) : "0") }
                        HTIStatusRow { Layout.fillWidth: true; label: qsTr("Current"); value: qsTr("%1 A").arg(root._battery ? root._factValue(root._battery.current, 0).toFixed(1) : "0.0") }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 10 // Độ dày thanh phần trăm pin.
                radius: 6
                color: "#0D1722"
                border.width: 1
                border.color: "#315161"

                Rectangle {
                    id: progressFill
                    width: parent.width * Math.max(0, Math.min(1, root._batteryPercent / 100))
                    height: parent.height
                    radius: parent.radius
                    color: root._batteryPercent > 20 ? "#4bc36a" : "#d84b4b"
                }

                Rectangle {
                    x: parent.width * Math.max(0, Math.min(1, root._batteryPercent / 100)) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: parent.height + 4
                    radius: 1
                    color: "#effff4"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                // Chiều cao khung Messages: tối thiểu 45, tối đa 60 px.
                Layout.preferredHeight: Math.max(45, Math.min(200, ScreenTools.defaultFontPixelHeight * 5))
                radius: 16
                color: "#C00B1524"
                border.color: logMouseArea.containsMouse ? "#35D7FF" : "#47A7FF"
                border.width: logMouseArea.containsMouse ? 2 : 1.5

                Rectangle {
                    id: logInfoBadge

                    anchors.left: parent.left
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(24, ScreenTools.defaultFontPixelHeight * 1.6)
                    height: width
                    radius: width / 2
                    color: "#15243A"
                    border.width: 1.5
                    border.color: "#47A7FF"

                    QGCLabel {
                        anchors.centerIn: parent
                        text: "i"
                        color: "#72C3FF"
                        font.pointSize: ScreenTools.smallFontPointSize + 2
                        font.bold: true
                    }
                }

                QGCLabel {
                    id: messageLabel
                    anchors.left: logInfoBadge.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                    anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 0.8
                    text: root.actionMessage !== "" ? root.actionMessage : root._messageText()
                    color: root.actionMessage !== "" ? "#F4D35E" : "#72C3FF"
                    font.pointSize: ScreenTools.smallFontPointSize // Cỡ chữ nội dung Messages.
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                }

                MouseArea {
                    id: logMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: logPopup.open()
                }
            }
        }
    }
}
