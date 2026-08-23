import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: root
    color: QGroundControl.globalPalette.window

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ScreenTools.defaultFontPixelWidth
        spacing: ScreenTools.defaultFontPixelHeight * 0.7

        QGCLabel { text: qsTr("Voice"); font.bold: true; font.pointSize: 18 }

        RowLayout {
            Layout.fillWidth: true
            QGCLabel { text: qsTr("Voice Alerts"); Layout.fillWidth: true }
            Switch { checked: htiVoiceManager.enabled; onToggled: htiVoiceManager.enabled = checked }
        }

        QGCLabel {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: htiVoiceManager.status
            color: htiVoiceManager.audioPackAvailable && htiVoiceManager.activeForCurrentLanguage ? "#65D98A" : QGroundControl.globalPalette.warningText
        }

        QGCLabel { text: qsTr("Language") }
        QGCComboBox {
            Layout.fillWidth: true
            model: [qsTr("Tiếng Việt")]
            currentIndex: 0
            enabled: false
        }

        QGCLabel { text: qsTr("Voice") }
        QGCTextField {
            Layout.fillWidth: true
            text: htiVoiceManager.voicePackName
            readOnly: true
        }

        QGCLabel { text: qsTr("Volume") }
        Slider {
            Layout.fillWidth: true
            from: 0
            to: 1
            value: htiVoiceManager.volume
            onMoved: htiVoiceManager.volume = value
        }

        QGCLabel { text: qsTr("Speech Rate: Recorded WAV") }

        SectionHeader { text: qsTr("Alert Groups"); Layout.fillWidth: true }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: ScreenTools.defaultFontPixelWidth

            QGCLabel { text: qsTr("Connection Alerts") }
            Switch { checked: htiVoiceManager.connectionAlerts; onToggled: htiVoiceManager.connectionAlerts = checked }
            QGCLabel { text: qsTr("Flight Mode Alerts") }
            Switch { checked: htiVoiceManager.flightModeAlerts; onToggled: htiVoiceManager.flightModeAlerts = checked }
            QGCLabel { text: qsTr("Battery Alerts") }
            Switch { checked: htiVoiceManager.batteryAlerts; onToggled: htiVoiceManager.batteryAlerts = checked }
            QGCLabel { text: qsTr("GPS Alerts") }
            Switch { checked: htiVoiceManager.gpsAlerts; onToggled: htiVoiceManager.gpsAlerts = checked }
            QGCLabel { text: qsTr("Pre-Flight Alerts") }
            Switch { checked: htiVoiceManager.preFlightAlerts; onToggled: htiVoiceManager.preFlightAlerts = checked }
            QGCLabel { text: qsTr("Mission Alerts") }
            Switch { checked: htiVoiceManager.missionAlerts; onToggled: htiVoiceManager.missionAlerts = checked }
        }

        QGCButton {
            text: qsTr("Test Voice")
            enabled: htiVoiceManager.enabled && htiVoiceManager.audioPackAvailable && htiVoiceManager.activeForCurrentLanguage
            onClicked: htiVoiceManager.testVoice()
        }
        Item { Layout.fillHeight: true }
    }
}
