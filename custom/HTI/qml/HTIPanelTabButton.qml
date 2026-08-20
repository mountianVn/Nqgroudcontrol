import QtQuick

import QGroundControl
import QGroundControl.Controls

HTIModernButton {
    id: root

    property bool selected: false
    property string tabVariant: "warning"

    variant: "tab"
    accentColor: tabVariant === "warning" ? "#63F29A" : "#B8C5D0"
    active: selected
    compact: false
    height: Math.max(39, Math.min(41, ScreenTools.defaultFontPixelHeight * 3.7))
}
