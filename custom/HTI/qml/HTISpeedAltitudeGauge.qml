import QtQuick

import QGroundControl.Controls

pragma ComponentBehavior: Bound

// Combined 440x220 frame. The image remains one intact background while
// telemetry is positioned in the matching left and right visual regions.
Item {
    id: root

    property real size: 80 // Kích thước cơ sở theo chiều cao; tăng để phóng to toàn bộ cụm.
    property real altitude: 0 // Độ cao thật từ activeVehicle, đơn vị mét.
    property real climbRate: 0 // Tốc độ lên/xuống thật, đơn vị m/s.
    property real groundSpeed: 0 // Groundspeed thật, đơn vị m/s; bên dưới đổi sang km/h.
    property bool hasVehicle: false // false sẽ hiển thị giá trị mặc định khi chưa kết nối vehicle.

    readonly property real _displayAltitude: isFinite(altitude) ? altitude : 0
    readonly property real _displayClimbRate: isFinite(climbRate) ? climbRate : 0
    readonly property real _speedKmh: Math.max(0, (isFinite(groundSpeed) ? groundSpeed : 0) * 3.6)
    readonly property real _dialCenterX: width * 0.7 // Tâm vòng speed theo chiều ngang; tăng/giảm để căn số 00.
    readonly property real _dialCenterY: height * 0.55 // Tâm vòng speed theo chiều dọc.
    readonly property real _dialLabelRadius: height * 0.28 // Bán kính nhỏ hơn để toàn bộ mốc 0-120 nằm trong vòng tròn.

    implicitWidth: size * 2
    implicitHeight: size
    clip: true

    Image {
        anchors.fill: parent
        source: "qrc:/qml/HTI/Speed_Alt_440x220.png"
        fillMode: Image.PreserveAspectFit // Giữ nguyên tỷ lệ ảnh 440x220, không crop hoặc méo.
        smooth: true
        mipmap: true
    }

    QGCLabel {
        x: root.width * -0.04 // Vị trí số altitude; tăng x để đẩy số sang phải.
        y: root.height * 0.38 // Vị trí theo chiều dọc của số altitude.
        width: root.width * 0.29 // Vùng căn phải của số altitude.
        text: root.hasVehicle ? root._displayAltitude.toFixed(1) : "0.0"
        color: "white"
        horizontalAlignment: Text.AlignRight
        font.pointSize: Math.max(11, root.height * 0.1) // Cỡ số altitude; tăng 0.18 để số lớn hơn.
        font.bold: true
    }

    QGCLabel {
        x: root.width * 0.28 // Vị trí đơn vị m; tăng x để tách khỏi số altitude.
        y: root.height * 0.38 // Căn giữa đơn vị m theo số altitude.
        width: root.width * 0.20 // Chiều rộng vùng đơn vị m.
        text: qsTr("m")
        color: "#c6cdd1"
        horizontalAlignment: Text.AlignLeft
        font.pointSize: Math.max(7, root.height * 0.1) // Đơn vị nhỏ hơn số chính.
    }

    QGCLabel {
        x: root.width * 0.17 // Vị trí capsule vertical speed theo chiều ngang.
        y: root.height * 0.745 // Vị trí capsule vertical speed; giảm y để đưa lên.
        width: root.width * 0.37 // Chiều rộng vùng text trong capsule.
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
        font.pointSize: Math.max(7, root.height * 0.06) // Cỡ chữ vertical speed.
    }

    QGCLabel {
        x: root.width * 0.575 // Vị trí vùng số speed; chỉnh x để căn đúng tâm vòng tròn.
        y: root.height * 0.35 // Vị trí số speed theo chiều dọc.
        width: root.width * 0.255 // Chiều rộng vùng căn giữa số speed.
        text: root.hasVehicle ? Math.round(root._speedKmh).toString().padStart(2, "0") : "00"
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: Math.max(14, root.height * 0.15) // Cỡ số speed chính; tăng 0.27 để phóng to.
        font.bold: true
    }

    QGCLabel {
        x: root.width * 0.58 // Căn cùng tâm với số speed.
        y: root.height * 0.70 // Vị trí đơn vị KM / h; tăng y để đưa xuống dưới số.
        width: root.width * 0.255 // Chiều rộng vùng đơn vị speed.
        text: qsTr("km / h")
        color: "#c6cdd1"
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: Math.max(7, root.height * 0.08) // Cỡ đơn vị nhỏ hơn số speed.
    }

    // Static dial graduations are part of the visual overlay; the actual
    // speed value remains telemetry-driven above the dial center.
    Repeater {
        model: [0, 20, 40, 60, 80, 100, 120]

        delegate: QGCLabel {
            required property int index
            required property var modelData
            readonly property real _angle: -125 + (index / 6) * 250 // Phân bố đều mốc từ góc dưới trái đến góc dưới phải.
            readonly property real _radians: _angle * Math.PI / 180

            x: root._dialCenterX + Math.sin(_radians) * root._dialLabelRadius - width / 2
            y: root._dialCenterY - Math.cos(_radians) * root._dialLabelRadius - height / 2
            width: root.height * 0.3 // Dùng chiều cao dial để vùng mốc không quá rộng.
            height: root.height * 0.10 // Đủ chỗ cho mốc 100/120 nhưng vẫn nằm trong vòng.
            text: modelData
            color: "#f4f7fb"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pointSize: Math.max(6, root.height * 0.01) // Cỡ mốc rõ hơn và scale theo kích thước dial.
            font.bold: true
        }
    }
}
