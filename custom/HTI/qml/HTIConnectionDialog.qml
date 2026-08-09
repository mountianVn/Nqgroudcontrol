import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.AppSettings
import QGroundControl.Controls

// HTI entry point for the existing QGC link configuration UI. The actual
// configuration, persistence and connection operations remain in QGC's
// LinkManager and LinkConfiguration implementations.
QGCPopupDialog {
    title: qsTr("Links")
    buttons: Dialog.Close

    LinkConfigurationManager {
        width: Math.min(ScreenTools.defaultFontPixelWidth * 48,
                        mainWindow.width - ScreenTools.defaultFontPixelWidth * 8)
    }
}
