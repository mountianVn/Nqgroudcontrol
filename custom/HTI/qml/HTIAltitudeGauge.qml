import QtQuick

import QGroundControl.Controls

// Left half of the shared 440x220 altitude/speed frame.
Item {
    id: root

    property real size:       80
    property real altitude:   0
    property real climbRate:  0
    property bool hasVehicle: false

    readonly property real _displayAltitude:  isFinite(altitude) ? altitude : 0
    readonly property real _displayClimbRate: isFinite(climbRate) ? climbRate : 0

    implicitWidth:  size
    implicitHeight: size
    clip:           true

    Image {
        anchors.left: parent.left
        width:        parent.width * 2
        height:       parent.height
        source:       "qrc:/qml/HTI/Speed_Alt_440x220.png"
        fillMode:     Image.Stretch
        smooth:       true
        mipmap:       true
    }

    QGCLabel {
        anchors.horizontalCenter: parent.horizontalCenter
        y:                        parent.height * 0.30
        width:                    parent.width * 0.68
        text:                     root.hasVehicle ? root._displayAltitude.toFixed(1) + " m" : "0 m"
        color:                    "white"
        horizontalAlignment:     Text.AlignHCenter
        elide:                    Text.ElideRight
        font.pointSize:           Math.max(8, root.size * 0.135)
        font.bold:                true
    }

    QGCLabel {
        anchors.horizontalCenter: parent.horizontalCenter
        y:                        parent.height * 0.59
        width:                    parent.width * 0.72
        text: {
            if (!root.hasVehicle) {
                return "0.0 m/s"
            }
            var sign = root._displayClimbRate > 0 ? "+" : ""
            return sign + root._displayClimbRate.toFixed(1) + " m/s"
        }
        color: {
            if (!root.hasVehicle || Math.abs(root._displayClimbRate) < 0.05) {
                return "#d0d5d9"
            }
            return root._displayClimbRate > 0 ? "#58d676" : "#ff7068"
        }
        horizontalAlignment: Text.AlignHCenter
        elide:               Text.ElideRight
        font.pointSize:      Math.max(6, root.size * 0.085)
    }
}
