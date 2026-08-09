import QtQuick

import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    property var parentToolInsets
    property var totalToolInsets: _toolInsets
    property var mapControl

    signal connectClicked()
    signal mapsClicked()
    signal zoomInClicked()
    signal zoomOutClicked()
    signal screenClicked()
    signal settingsClicked()

    QGCPopupDialogFactory {
        id: connectionDialogFactory
        dialogComponent: HTIConnectionDialog {}
    }

    QGCToolInsets {
        id: _toolInsets

        leftEdgeTopInset: root.parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset: root.parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset: root.parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset: root.parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset: root.parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset: root.parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset: root.parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset: root.parentToolInsets.topEdgeCenterInset
        topEdgeRightInset: root.parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset: root.parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset: root.parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset: root.parentToolInsets.bottomEdgeRightInset
    }

    HTILeftToolBar {
        id: leftToolBar

        anchors.left: parent.left
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
        anchors.verticalCenter: parent.verticalCenter
        z: QGroundControl.zOrderTopMost

        onConnectClicked: {
            root.connectClicked()
            connectionDialogFactory.open()
        }
        onMapsClicked: {
            root.mapsClicked()
            mainWindow.showSettingsTool(qsTr("Maps"))
        }
        onZoomInClicked: {
            root.zoomInClicked()
            if (root.mapControl) {
                root.mapControl.zoomLevel = Math.max(root.mapControl.zoomLevel + 1, 0)
            }
        }
        onZoomOutClicked: {
            root.zoomOutClicked()
            if (root.mapControl) {
                root.mapControl.zoomLevel = Math.max(root.mapControl.zoomLevel - 1, 0)
            }
        }
        onScreenClicked: root.screenClicked()
        onSettingsClicked: {
            root.settingsClicked()
            mainWindow.showSettingsTool()
        }
    }
}
