import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

pragma ComponentBehavior: Bound

Item {
    id: root

    property var activeVehicle
    property real preferredWidth: 230
    property bool expanded: true

    readonly property bool hasActions: !!activeVehicle && actionManager.actions.count > 0
    readonly property real compactSize: Math.max(30, ScreenTools.defaultFontPixelHeight * 1.9)

    implicitWidth: expanded ? preferredWidth : compactSize
    implicitHeight: expanded ? panelColumn.implicitHeight + ScreenTools.defaultFontPixelHeight : compactSize
    visible: hasActions

    MavlinkActionManager {
        id: actionManager

        actionFileNameFact: QGroundControl.settingsManager.mavlinkActionsSettings.flyViewActionsFile
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: "#df10171e"
        border.color: "#52616d"
        border.width: 1
        visible: root.expanded
    }

    ColumnLayout {
        id: panelColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: ScreenTools.defaultFontPixelWidth * 0.55
        spacing: ScreenTools.defaultFontPixelHeight * 0.20
        visible: root.expanded

        QGCLabel {
            Layout.fillWidth: true
            text: qsTr("Camera / Gimbal Actions")
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: ScreenTools.smallFontPointSize
            font.weight: Font.DemiBold
        }

        Repeater {
            model: root.hasActions ? actionManager.actions : undefined

            delegate: QGCButton {
                required property var object

                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(28, ScreenTools.defaultFontPixelHeight * 1.8)
                text: object.label
                enabled: !!root.activeVehicle
                font.pointSize: ScreenTools.smallFontPointSize

                ToolTip.visible: hovered
                ToolTip.delay: 500
                ToolTip.text: object.description

                onClicked: object.sendTo(root.activeVehicle)
            }
        }
    }

    QGCButton {
        id: visibilityButton

        anchors.top: parent.top
        anchors.right: parent.right
        width: root.compactSize
        height: root.compactSize
        leftPadding: 4
        rightPadding: 4
        topPadding: 4
        bottomPadding: 4
        iconSource: root.expanded ? "/res/chevron-double-right.svg" : "/res/chevron-double-left.svg"
        backgroundColor: root.expanded ? "#405466" : "#1677c8"
        z: 2

        ToolTip.visible: hovered
        ToolTip.delay: 400
        ToolTip.text: root.expanded ? qsTr("Hide camera actions") : qsTr("Show camera actions")

        onClicked: root.expanded = !root.expanded
    }
}
