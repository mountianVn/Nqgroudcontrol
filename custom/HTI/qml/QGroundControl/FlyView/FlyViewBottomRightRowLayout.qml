import QtQuick

// The HTI bottom-right HUD replaces the stock telemetry value bar and its
// selectable instrument panel. Keep the interface expected by
// FlyViewWidgetLayer so its inset calculations remain valid.
Item {
    id: root

    property real spacing: 0
    readonly property real rightEdgeBottomInset: 0
    readonly property real bottomEdgeCenterInset: 0
    readonly property real bottomEdgeRightInset: 0

    implicitWidth: 0
    implicitHeight: 0
    width: 0
    height: 0
    visible: false
}
