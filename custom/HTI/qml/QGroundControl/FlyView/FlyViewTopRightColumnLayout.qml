import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls
import QGroundControl.FlyView

// HTI places PhotoVideoControl in FlyViewCustomLayer so it is not hidden
// behind the right-side Functions panel. Keep terrain progress unchanged.
ColumnLayout {
    spacing: ScreenTools.defaultFontPixelHeight / 2

    TerrainProgress {
        Layout.fillWidth: true
    }
}
