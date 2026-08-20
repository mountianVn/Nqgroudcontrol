import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

Item {
    id: root

    property string label: ""
    property string value: ""
    // Kept for source compatibility with older HTI rows; the compact layout
    // intentionally does not render a per-row icon.
    property string glyph: ""
    property real labelWidth: ScreenTools.defaultFontPixelWidth * 12.5 // Chiều rộng cột tên; tăng nếu label bị cắt.

    implicitHeight: Math.max(ScreenTools.defaultFontPixelHeight * 1.1, 18) // Chiều cao mỗi hàng thông số.

    RowLayout {
        anchors.fill: parent
        spacing: ScreenTools.defaultFontPixelWidth * 0.3 // Khoảng cách giữa tên, dấu hai chấm và giá trị.

        QGCLabel {
            Layout.preferredWidth: root.labelWidth
            text: root.label
            color: "#ffffff"
            font.pointSize: ScreenTools.smallFontPointSize + 1 // Cỡ chữ tên thông số bên trái.
            elide: Text.ElideRight
        }

        QGCLabel {
            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 0.9 // Chiều rộng cột dấu hai chấm.
            text: ":"
            color: "#35D7FF"
            font.pointSize: ScreenTools.smallFontPointSize + 1 // Cỡ chữ dấu hai chấm.
        }

        QGCLabel {
            Layout.fillWidth: true
            text: root.value
            color: "#ffffff"
            font.pointSize: ScreenTools.smallFontPointSize + 1 // Cỡ chữ giá trị bên phải.
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }
}
