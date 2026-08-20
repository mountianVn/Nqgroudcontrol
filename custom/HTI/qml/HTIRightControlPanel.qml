import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property int currentTab: 0
    property real preferredPanelWidth: 312 // Chiều rộng mong muốn của toàn bộ panel bên phải.

    signal setRadiusRequested(real radius)

    implicitWidth: preferredPanelWidth
    // 250 là chiều rộng tối thiểu; 0.32 là tỷ lệ tối đa theo chiều rộng màn hình.
    width: Math.min(preferredPanelWidth, Math.max(250, parent ? parent.width * 0.32 : preferredPanelWidth))
    implicitHeight: panelLayout.implicitHeight
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: 20 // Bo góc ngoài kiểu dark glass.
        color: "#D908111A" // Nền xanh đen, trong suốt khoảng 85%.
        border.color: "#31C8FF"
        border.width: 1.5
        antialiasing: true
    }

    ColumnLayout {
        id: panelLayout
        anchors.fill: parent
        anchors.margins: ScreenTools.defaultFontPixelWidth * 0.5 // Khoảng đệm từ nội dung tới viền panel.
        spacing: ScreenTools.defaultFontPixelHeight * 0.25 // Khoảng cách dọc giữa các phần trong panel.

        RowLayout {
            Layout.fillWidth: true
            spacing: ScreenTools.defaultFontPixelWidth * 0.45 // Khoảng cách giữa tab Functions và Mission.

            HTIPanelTabButton {
                Layout.fillWidth: true
                text: qsTr("Functions")
                selected: root.currentTab === 0
                tabVariant: "warning"
                onClicked: root.currentTab = 0
            }

            HTIPanelTabButton {
                Layout.fillWidth: true
                text: qsTr("Mission")
                selected: root.currentTab === 1
                tabVariant: "blue"
                // Mở toàn bộ môi trường Plan của QGC thay vì tab Mission thu gọn.
                onClicked: {
                    if (mainWindow.allowViewSwitch()) {
                        mainWindow.showPlanView()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#2C7188"
        }

        Loader {
            id: panelContent
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: root.currentTab === 0 ? functionsComponent : missionComponent
        }
    }

    Component {
        id: functionsComponent

        HTIFunctionsPanel {
            activeVehicle: root.activeVehicle
            onSetRadiusRequested: root.setRadiusRequested(radius)
        }
    }

    Component {
        id: missionComponent

        HTIMissionPanel {
            activeVehicle: root.activeVehicle
        }
    }
}
