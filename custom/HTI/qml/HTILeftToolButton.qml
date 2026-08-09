import QtQuick

import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: root

    property string label
    property string iconSource
    property bool active: false

    signal clicked()

    radius: 5
    color: !enabled ? "#202328" : active ? "#3e718f" : mouseArea.pressed ? "#2d5268" : mouseArea.containsMouse ? "#343a40" : "#252a2f"
    border.width: active || mouseArea.containsMouse ? 1 : 0
    border.color: active ? "#82c8e8" : "#56616b"
    opacity: enabled ? 1 : 0.5

    QGCColoredImage {
        id: icon

        anchors.top: parent.top
        anchors.topMargin: Math.max(4, parent.height * 0.12)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width * 0.38, parent.height * 0.42)
        height: width
        source: root.iconSource
        color: "#f2f5f7"
        fillMode: Image.PreserveAspectFit
        sourceSize.width: width
        sourceSize.height: height
    }

    QGCLabel {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(3, parent.height * 0.09)
        text: root.label
        color: "#f2f5f7"
        font.pointSize: ScreenTools.smallFontPointSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: !ScreenTools.isMobile
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
