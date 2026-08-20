import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

import QGroundControl.Controls

// Circular compass with a rotating cardinal dial and a fixed heading readout.
Item {
    id: root

    property real size:       80
    property real heading:    0
    property bool hasVehicle: false

    readonly property real _displayHeading: {
        var value = Number(root.heading)
        if (!isFinite(value)) {
            return 0
        }
        return ((value % 360) + 360) % 360
    }

    implicitWidth:  size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius:       width / 2
        color:        Qt.rgba(0, 0, 0, 0.86)
        border.width: 1
        border.color: "#d8dde0"

        Item {
            id: compassDial

            anchors.centerIn: parent
            width:            root.size - 10
            height:           root.size - 10
            rotation:         -root._displayHeading

            Repeater {
                model: [
                    { angle: 0,   label: "N", cardinal: true },
                    { angle: 30,  label: "",  cardinal: false },
                    { angle: 60,  label: "",  cardinal: false },
                    { angle: 90,  label: "E", cardinal: true },
                    { angle: 120, label: "",  cardinal: false },
                    { angle: 150, label: "",  cardinal: false },
                    { angle: 180, label: "S", cardinal: true },
                    { angle: 210, label: "",  cardinal: false },
                    { angle: 240, label: "",  cardinal: false },
                    { angle: 270, label: "W", cardinal: true },
                    { angle: 300, label: "",  cardinal: false },
                    { angle: 330, label: "",  cardinal: false }
                ]

                Item {
                    anchors.fill: parent
                    rotation:    modelData.angle

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y:                        2
                        width:                    modelData.cardinal ? 2 : 1
                        height:                   modelData.cardinal ? 8 : 5
                        color:                    modelData.label === "N" ? "#58d7f5" : "#dce2e5"
                    }

                    QGCLabel {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y:                        modelData.cardinal ? 10 : 8
                        text:                     modelData.label
                        color:                    modelData.label === "N" ? "#58d7f5" : "#c1c9ce"
                        font.pointSize:           modelData.cardinal ? Math.max(7, root.size * 0.10) : Math.max(6, root.size * 0.075)
                        font.bold:                modelData.cardinal
                    }
                }
            }
        }

        QGCLabel {
            anchors.centerIn: parent
            text:             root.hasVehicle ? root._displayHeading.toFixed(0) + "°" : "0°"
            color:            "white"
            font.pointSize:   Math.max(11, root.size * 0.1)
            font.bold:        true
        }

        // Fixed north pointer.
        Shape {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            anchors.topMargin:        2
            width:                    9
            height:                   9

            ShapePath {
                strokeWidth: 0
                fillColor:   "#58d7f5"
                startX:      4.5
                startY:      0
                PathLine { x: 9; y: 9 }
                PathLine { x: 4.5; y: 6 }
                PathLine { x: 0; y: 9 }
                PathLine { x: 4.5; y: 0 }
            }
        }
    }
}
