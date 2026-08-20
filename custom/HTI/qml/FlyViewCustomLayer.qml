import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap
import "qrc:/qml/HTI"

Item {
    id: root

    property var parentToolInsets
    property var totalToolInsets: _toolInsets
    property var mapControl
    readonly property var _activeVehicle: QGroundControl.multiVehicleManager
        ? QGroundControl.multiVehicleManager.activeVehicle
        : null

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

    // Nút chụp ảnh/quay video: x = 3.8%, y = 27.5% theo kích thước Fly View.
    // Dùng component camera gốc của QGC, chỉ thay đổi vị trí hiển thị.
    Loader {
        id: photoVideoControlLoader

        x: parent.width * 0.035
        y: parent.height * 0.0001
        sourceComponent: root._activeVehicle && root._activeVehicle.cameraManager
            ? photoVideoControlComponent
            : undefined
        z: QGroundControl.zOrderTopMost
    }

    Component {
        id: photoVideoControlComponent

        PhotoVideoControl {}
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

    // === LEFT TOOLBAR ===
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

    // === BOTTOM-RIGHT TELEMETRY HUD ===
    HTIBottomRightHud {
        id: telemetryHud

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // Cộng thêm 16 px để cụm gauge không chạm mép phải màn hình.
        anchors.rightMargin: Math.max(12, Math.min(20, ScreenTools.defaultFontPixelWidth * 2)) + 16
        anchors.bottomMargin: Math.max(12, Math.min(20, ScreenTools.defaultFontPixelWidth * 2))

        z: QGroundControl.zOrderTopMost
    }

    // Right-side controls stay in the overlay layer and reserve the bottom HUD area.
    HTIRightControlPanel {
        id: rightControlPanel

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Math.max(8, ScreenTools.defaultFontPixelWidth)
        anchors.topMargin: Math.max(8, ScreenTools.defaultFontPixelHeight * 0.35)
        height: Math.min(rightControlPanel.implicitHeight,
                         Math.max(0, parent.height - anchors.topMargin - telemetryHud.height - ScreenTools.defaultFontPixelHeight * 1.5))

        z: QGroundControl.zOrderTopMost - 1
    }

    // Hiển thị trực tiếp toàn bộ action từ JSON đã chọn, không cần mở menu Actions.
    HTIMavlinkActionsPanel {
        id: mavlinkActionsPanel

        anchors.top: rightControlPanel.top
        anchors.right: rightControlPanel.left
        anchors.rightMargin: Math.max(8, ScreenTools.defaultFontPixelWidth)
        activeVehicle: root._activeVehicle
        z: QGroundControl.zOrderTopMost - 1
    }
}
