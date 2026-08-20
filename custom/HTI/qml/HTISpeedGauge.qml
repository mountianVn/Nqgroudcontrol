import QtQuick

import QGroundControl.Controls

// Right half of the shared 440x220 altitude/speed frame.
Item {
    id: root

    property real size:       80
    property real groundSpeed: 0
    property bool hasVehicle:  false

    readonly property real _speedKmh: Math.max(0, (isFinite(groundSpeed) ? groundSpeed : 0) * 3.6)

    implicitWidth:  size
    implicitHeight: size
    clip:           true

    Image {
        x:          -parent.width
        width:      parent.width * 2
        height:     parent.height
        source:     "qrc:/qml/HTI/Speed_Alt_440x220.png"
        fillMode:   Image.Stretch
        smooth:     true
        mipmap:     true
    }

    QGCLabel {
        anchors.horizontalCenter: parent.horizontalCenter
        y:                        parent.height * 0.27
        width:                    parent.width * 0.60
        text:                     root.hasVehicle ? Math.round(root._speedKmh).toString().padStart(2, "0") : "00"
        color:                    "white"
        horizontalAlignment:     Text.AlignHCenter
        elide:                    Text.ElideRight
        font.pointSize:           Math.max(10, root.size * 0.20)
        font.bold:                true
    }

    QGCLabel {
        anchors.horizontalCenter: parent.horizontalCenter
        y:                        parent.height * 0.64
        width:                    parent.width * 0.78
        text:                     qsTr("KM / h")
        color:                    "#c6cdd1"
        horizontalAlignment:     Text.AlignHCenter
        elide:                    Text.ElideRight
        font.pointSize:           Math.max(6, root.size * 0.085)
    }
}
