import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

Button {
    id: root

    property string iconSource: ""
    property string variant: "secondary"
    property bool active: false
    property bool compact: false
    property color accentColor: "#00000000"

    readonly property color _accentColor: {
        if (root.accentColor.a > 0) {
            return root.accentColor
        }
        switch (root.variant) {
        case "primary":
        case "green": return "#63F29A"
        case "blue": return "#47A7FF"
        case "danger": return "#FF5A52"
        case "tab": return "#35D7FF"
        case "secondary":
        default: return "#35D7FF"
        }
    }
    readonly property color _surfaceStart: !root.enabled ? "#E7E7E7" :
                                                   root.pressed ? "#111A22" :
                                                   root.hovered ? "#354550" : "#27313A"
    readonly property color _surfaceEnd: !root.enabled ? "#E7E7E7" :
                                                 root.pressed ? "#0B1117" :
                                                 root.hovered ? "#1C2A35" : "#111A22"
    readonly property color _borderColor: {
        if (!root.enabled) {
            return "#B9B9B9"
        }
        if (root.pressed) {
            return root._accentColor
        }
        if (root.hovered || root.activeFocus) {
            return "#35D7FF"
        }
        return root.active ? root._accentColor : "#71818D"
    }
    readonly property color _textColor: !root.enabled ? "#8A8A8A" :
                                             root.variant === "danger" ? "#FF5A52" :
                                             root.variant === "blue" ? "#47A7FF" : "#F4F8FB"
    readonly property real _contentOffset: root.pressed ? 1 : (root.hovered ? -1 : 0)

    implicitHeight: compact ? 34 : 36
    hoverEnabled: true
    padding: 0
    leftPadding: ScreenTools.defaultFontPixelWidth * 0.9
    rightPadding: ScreenTools.defaultFontPixelWidth * 0.9
    topPadding: 0
    bottomPadding: 0
    font.family: ScreenTools.normalFontFamily
    font.pointSize: ScreenTools.smallFontPointSize + 0.5
    font.weight: Font.DemiBold
    focusPolicy: Qt.StrongFocus

    background: Item {
        Rectangle {
            anchors.fill: parent
            radius: root.compact ? 14 : 16
            color: "#50000000"
            opacity: !root.enabled ? 0.04 : (root.pressed ? 0.05 : (root.hovered ? 0.18 : 0.10))
            transform: Translate { y: root.pressed ? 1 : 2 }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.compact ? 14 : 16
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root._surfaceStart }
                GradientStop { position: 1.0; color: root._surfaceEnd }
            }
            border.width: root.active || root.activeFocus || root.hovered || root.pressed ? 2 : 1.5
            border.color: root._borderColor
            antialiasing: true
            transform: Translate { y: root._contentOffset }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Math.max(12, parent.width * 0.18)
                anchors.rightMargin: Math.max(12, parent.width * 0.18)
                height: root.active ? 3 : 2
                radius: height / 2
                color: root._accentColor
                opacity: root.enabled && root.active ? 1 : 0
            }
        }
    }

    contentItem: Item {
        RowLayout {
            anchors.fill: parent
            anchors.topMargin: root._contentOffset
            anchors.bottomMargin: -root._contentOffset
            spacing: ScreenTools.defaultFontPixelWidth * 0.45

            QGCColoredImage {
                Layout.preferredWidth: root.iconSource !== "" ? ScreenTools.defaultFontPixelHeight * 1.05 : 0
                Layout.preferredHeight: root.iconSource !== "" ? ScreenTools.defaultFontPixelHeight * 1.05 : 0
                visible: root.iconSource !== ""
                source: root.iconSource
                color: root._textColor
                fillMode: Image.PreserveAspectFit
                sourceSize.height: height
            }

            QGCLabel {
                Layout.fillWidth: true
                text: root.text
                color: root._textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font: root.font
            }
        }
    }

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
