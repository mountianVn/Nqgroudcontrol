import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

import QGroundControl.Controls

// Circular artificial horizon driven by the vehicle roll and pitch Facts.
Item {
    id: root

    property real size:       88
    property real roll:       0
    property real pitch:      0
    property bool hasVehicle: false

    readonly property real _displayRoll:  isFinite(roll) ? roll : 0
    readonly property real _displayPitch: isFinite(pitch) ? pitch : 0
    readonly property real _pitchScale:   root.size / 48
    readonly property var  _bankAngles:   [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]
    readonly property color _skyColor:    "#4b91d5"
    readonly property color _groundColor: "#74b842"
    readonly property color _markColor:   "#ffffff"

    implicitWidth:  size
    implicitHeight: size

    // The moving scene is rotated as one unit. Pitch translation happens on
    // horizonContent inside that rotated coordinate system, matching the
    // transform order of a real artificial horizon.
    Item {
        id: instrument

        anchors.fill: parent
        visible: false

        Item {
            id: movingLayer

            anchors.fill:  parent
            rotation:       -root._displayRoll
            transformOrigin: Item.Center

            Item {
                id: horizonContent

                anchors.horizontalCenter: parent.horizontalCenter
                width:                    root.size * 2
                height:                   width
                y:                        (parent.height - height) / 2 + root._displayPitch * root._pitchScale

                Rectangle {
                    anchors.fill: parent
                    color:        root._skyColor
                }

                Rectangle {
                    x:      0
                    y:      parent.height / 2
                    width:  parent.width
                    height: parent.height / 2
                    color:  root._groundColor
                }

                Rectangle {
                    x:         0
                    y:         parent.height / 2 - 1
                    width:     parent.width
                    height:    2
                    color:     root._markColor
                }

                // Pitch marks translate with the horizon and rotate with it.
                Repeater {
                    model: [10, -10]

                    Item {
                        property real markValue: modelData

                        anchors.fill: parent

                        Rectangle {
                            x:         parent.width / 2 - root.size * 0.14 / 2 - root.size * 0.22
                            y:         parent.height / 2 - parent.markValue * root._pitchScale
                            width:     root.size * 0.22
                            height:    1
                            color:     root._markColor
                        }

                        Rectangle {
                            x:         parent.width / 2 + root.size * 0.14 / 2
                            y:         parent.height / 2 - parent.markValue * root._pitchScale
                            width:     root.size * 0.22
                            height:    1
                            color:     root._markColor
                        }

                        QGCLabel {
                            x:                   parent.width / 2 - root.size * 0.14 / 2 - root.size * 0.22 - width - 2
                            y:                   parent.height / 2 - parent.markValue * root._pitchScale - height / 2
                            width:               root.size * 0.12
                            text:                parent.markValue > 0 ? "10" : "-10"
                            color:               root._markColor
                            horizontalAlignment: Text.AlignRight
                            font.pointSize:      Math.max(6, root.size * 0.075)
                        }

                        QGCLabel {
                            x:              parent.width / 2 + root.size * 0.14 / 2 + root.size * 0.22 + 2
                            y:              parent.height / 2 - parent.markValue * root._pitchScale - height / 2
                            width:          root.size * 0.12
                            text:           parent.markValue > 0 ? "10" : "-10"
                            color:          root._markColor
                            font.pointSize: Math.max(6, root.size * 0.075)
                        }
                    }
                }
            }

            // The bank scale is part of the moving attitude scene. The red
            // marker below remains fixed, so the relative angle stays legible.
            Item {
                id: bankScale

                anchors.fill: parent

                Repeater {
                    model: root._bankAngles

                    Item {
                        anchors.fill: parent
                        rotation:    modelData

                        Rectangle {
                            readonly property bool isZero:  Math.abs(modelData) < 0.01
                            readonly property bool isMajor: isZero || Math.abs(modelData) >= 30

                            x:         parent.width / 2 - width / 2
                            y:         isZero ? 10 : 4
                            width:     isZero ? 2 : 1.2
                            height:    isMajor ? 8 : 5
                            radius:    width / 2
                            color:     root._markColor
                        }
                    }
                }
            }
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        // MultiEffect samples the mask as an offscreen texture.
        layer.enabled: true
        visible:       false

        Rectangle {
            anchors.fill: parent
            radius:       width / 2
            color:        "black"
        }
    }

    MultiEffect {
        source:       instrument
        anchors.fill: instrument
        maskEnabled:  true
        maskSource:   mask
    }

    // Fixed aircraft reference symbol.
    Rectangle {
        anchors.centerIn: parent
        width:            root.size * 0.34
        height:           2
        radius:           1
        color:            "#ffe04b"
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
        width:                    2
        height:                   root.size * 0.18
        radius:                   1
        color:                    "#ffe04b"
    }

    // Fixed roll-reference triangle at the top of the bezel.
    Shape {
        width:  8
        height: 8
        anchors {
            horizontalCenter: parent.horizontalCenter
            top:              parent.top
            topMargin:        2
        }

        ShapePath {
            strokeWidth: 0
            fillColor:   "#ef4b4b"
            startX:      0
            startY:      0
            PathLine { x: 8; y: 0 }
            PathLine { x: 4; y: 8 }
            PathLine { x: 0; y: 0 }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius:       width / 2
        color:        Qt.rgba(0, 0, 0, 0)
        border.width: 1.5
        border.color: "#f4f7f8"
    }
}
