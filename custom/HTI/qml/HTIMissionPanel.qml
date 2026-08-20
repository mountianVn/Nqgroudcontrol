import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    implicitHeight: missionLayout.implicitHeight

    function _factValue(fact, fallback) {
        if (!fact || typeof fact.rawValue === "undefined") {
            return fallback
        }
        const value = Number(fact.rawValue)
        return isFinite(value) ? value : fallback
    }

    ColumnLayout {
        id: missionLayout
        anchors.fill: parent
        anchors.margins: ScreenTools.defaultFontPixelWidth
        spacing: ScreenTools.defaultFontPixelHeight * 0.7

        QGCLabel {
            Layout.fillWidth: true
            text: qsTr("Mission")
            color: "#ffffff"
            font.pointSize: ScreenTools.mediumFontPointSize
            font.weight: Font.DemiBold
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.4
            radius: 5
            color: "#7a101418"
            border.color: "#40505c"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPixelWidth
                spacing: 2

                QGCLabel {
                    Layout.fillWidth: true
                    text: root.activeVehicle ? qsTr("Mode: %1").arg(root.activeVehicle.flightMode || qsTr("Unknown")) : qsTr("Mode: N/A")
                    color: "#d7e0e8"
                    font.pointSize: ScreenTools.smallFontPointSize
                    elide: Text.ElideRight
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: root.activeVehicle ? qsTr("Current WP: %1").arg(root._factValue(root.activeVehicle.vehicle.missionItemIndex, 0)) : qsTr("Current WP: N/A")
                    color: "#d7e0e8"
                    font.pointSize: ScreenTools.smallFontPointSize
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: root.activeVehicle ? qsTr("Next WP: %1 m").arg(Math.round(root._factValue(root.activeVehicle.vehicle.distanceToNextWP, 0))) : qsTr("Next WP: N/A")
                    color: "#d7e0e8"
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }
        }

        HTIModernButton {
            Layout.fillWidth: true
            text: qsTr("Start Mission")
            variant: "primary"
            enabled: !!root.activeVehicle
            onClicked: {
                if (root.activeVehicle) {
                    root.activeVehicle.startMission()
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
