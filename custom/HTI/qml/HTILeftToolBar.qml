import QtQuick

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: root

    property real buttonSpacing: 2
    property real horizontalPadding: 5
    property real verticalPadding: 5
    property real buttonHeight: Math.max(34, Math.min(56, (parent.height - verticalPadding * 2 - buttonSpacing * 5) / 6))

    signal connectClicked()
    signal mapsClicked()
    signal zoomInClicked()
    signal zoomOutClicked()
    signal screenClicked()
    signal settingsClicked()

    width: Math.max(68, ScreenTools.defaultFontPixelWidth * 7)
    height: verticalPadding * 2 + buttonHeight * 6 + buttonSpacing * 5
    radius: 7
    color: "#16191d"
    border.width: 1
    border.color: "#46505a"

    Column {
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        anchors.topMargin: root.verticalPadding
        anchors.bottomMargin: root.verticalPadding
        spacing: root.buttonSpacing

        HTILeftToolButton {
            width: parent.width
            height: root.buttonHeight
            label: qsTr("Connect")
            // Reuse the same icon as QGC's Comm Links entry.
            iconSource: "qrc:/InstrumentValueIcons/usb.svg"
            onClicked: root.connectClicked()
        }

        HTILeftToolButton {
            width: parent.width
            height: root.buttonHeight
            label: qsTr("Maps")
            iconSource: "/InstrumentValueIcons/map.svg"
            onClicked: root.mapsClicked()
        }

        HTILeftToolButton {
            width: parent.width
            height: root.buttonHeight
            label: qsTr("Zoom In")
            iconSource: "/InstrumentValueIcons/zoom-in.svg"
            onClicked: root.zoomInClicked()
        }

        HTILeftToolButton {
            width: parent.width
            height: root.buttonHeight
            label: qsTr("Zoom Out")
            iconSource: "/InstrumentValueIcons/zoom-out.svg"
            onClicked: root.zoomOutClicked()
        }

        HTILeftToolButton {
            width: parent.width
            height: root.buttonHeight
            label: qsTr("Screen")
            iconSource: "/InstrumentValueIcons/screen-full.svg"
            onClicked: root.screenClicked()
        }

        HTILeftToolButton {
            width: parent.width
            height: root.buttonHeight
            label: qsTr("Settings")
            iconSource: "qrc:/res/gear-black.svg"
            onClicked: root.settingsClicked()
        }
    }
}
