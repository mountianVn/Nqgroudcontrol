import QtQuick

import QGroundControl
import QGroundControl.Controls

QGCButton {
    id: root

    property color fillColor: "#3d424a"
    property color disabledFillColor: "#2a2e34"
    property color pressedFillColor: Qt.darker(fillColor, 1.18)

    textColor: "#ffffff"
    backgroundColor: enabled ? (pressed ? pressedFillColor : fillColor) : disabledFillColor
    backRadius: 4
    pointSize: ScreenTools.smallFontPointSize
    height: Math.max(30, Math.min(34, ScreenTools.defaultFontPixelHeight * 3.1))
    fontWeight: Font.DemiBold
}
