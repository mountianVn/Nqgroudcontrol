import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls

// Two-line telemetry pill with an optional tinted QGC icon.
Item {
    id: root

    property string label:      ""
    property string value:      "--"
    property url    iconSource: ""
    property color  bgColor:    "#4d555b"
    property color  textColor:  "white"

    readonly property real _pillHeight: 42
    readonly property real _horizontalPadding: 8

    implicitWidth:  92
    implicitHeight: _pillHeight

    Rectangle {
        anchors.fill: parent
        radius:       height / 2
        color:        root.bgColor
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)

        RowLayout {
            anchors.fill:       parent
            anchors.leftMargin: root._horizontalPadding
            anchors.rightMargin: root._horizontalPadding
            spacing:             6

            QGCColoredImage {
                Layout.preferredWidth:  18
                Layout.preferredHeight: 18
                visible:                root.iconSource.toString().length > 0
                source:                 root.iconSource
                color:                  root.textColor
                fillMode:               Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing:          0

                QGCLabel {
                    Layout.fillWidth: true
                    text:             root.label
                    color:            root.textColor
                    font.pointSize:   9
                    font.bold:        true
                    elide:            Text.ElideRight
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text:             root.value
                    color:            root.textColor
                    font.pointSize:   10
                    elide:            Text.ElideRight
                }
            }
        }
    }
}
