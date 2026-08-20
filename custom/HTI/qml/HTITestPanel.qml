import QtQuick
import QGroundControl
import QGroundControl.Controls

Rectangle {
    id: root

    implicitWidth: 420
    implicitHeight: 180
    color: qgcPal.window

    QGCLabel {
        anchors.centerIn: parent
        text: qsTr("NGroundControl Custom Panel")
        color: qgcPal.text
    }
}
