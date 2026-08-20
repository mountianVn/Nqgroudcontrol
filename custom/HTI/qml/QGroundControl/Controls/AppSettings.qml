import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.AppSettings

Item {
    id:     settingsView
    anchors.fill: parent
    clip:  false

    readonly property real _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
    readonly property real _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
    readonly property real _horizontalMargin:   16
    readonly property real _verticalMargin:     12
    readonly property real _headerHeight:       48
    readonly property real _sidebarWidth:        260  // Fixed sidebar width

    property bool _first: true
    property bool _commingFromRIDSettings: false
    property int  _selectedPageIndex: -1
    property int  _selectedSectionIndex: -1
    property var  _expandedPages: ({})  // pageIndex -> bool
    property int  _expandedRevision: 0  // bumped to trigger re-evaluation
    property string _searchQuery: ""

    function _setExpanded(pageIndex, value) {
        _expandedPages[pageIndex] = value
        _expandedRevision++
    }

    function _isExpanded(pageIndex) {
        void _expandedRevision  // create binding dependency
        return !!_expandedPages[pageIndex]
    }

    // Search: returns array of matching section indices for a page, or empty if no match
    function _matchingSections(pageIndex) {
        var query = _searchQuery.toLowerCase().trim()
        if (query === "") return []  // empty = no filtering

        var entry = settingsPagesModel.get(pageIndex)
        if (!entry) return []

        // Check English search terms
        var termsStr = entry.searchTerms
        var matches = []
        var matched = {}
        if (termsStr && termsStr !== "") {
            try {
                var terms = JSON.parse(termsStr)
                for (var i = 0; i < terms.length; i++) {
                    if (terms[i].terms.indexOf(query) !== -1) {
                        matched[terms[i].section] = true
                        matches.push(terms[i].section)
                    }
                }
            } catch(e) { console.warn("AppSettings: JSON parse error in searchTerms:", e) }
        }

        // Check translatable terms (translated at runtime)
        var trStr = entry.translatableTerms
        if (trStr && trStr !== "") {
            try {
                var trTerms = JSON.parse(trStr)
                for (var j = 0; j < trTerms.length; j++) {
                    if (matched[trTerms[j].section]) continue
                    var ctx = trTerms[j].context
                    var tList = trTerms[j].terms
                    for (var k = 0; k < tList.length; k++) {
                        if (qsTranslate(ctx, tList[k]).toLowerCase().indexOf(query) !== -1) {
                            matched[trTerms[j].section] = true
                            matches.push(trTerms[j].section)
                            break
                        }
                    }
                }
            } catch(e) { console.warn("AppSettings: JSON parse error in translatableTerms:", e) }
        }

        return matches
    }

    // Does this page have any search matches? (or is search empty = show all)
    function _pageMatchesSearch(pageIndex) {
        if (_searchQuery.trim() === "") return true
        return _matchingSections(pageIndex).length > 0
    }

    function _navigateTo(pageIndex, sectionIndex) {
        var entry = settingsPagesModel.get(pageIndex)
        if (!entry || entry.name === "Divider") return

        var url = entry.url
        _selectedSectionIndex = sectionIndex

        if (_selectedPageIndex !== pageIndex) {
            _selectedPageIndex = pageIndex
            rightPanel.source = url
        }

        // Apply section filter after the page is loaded
        if (rightPanel.item && typeof rightPanel.item.sectionFilter !== "undefined") {
            rightPanel.item.sectionFilter = sectionIndex
        }
    }

    function showSettingsPage(settingsPage) {
        for (var i = 0; i < settingsPagesModel.count; i++) {
            var entry = settingsPagesModel.get(i)
            if (entry && entry.name === settingsPage) {
                _navigateTo(i, -1)
                break
            }
        }
    }

    // This need to block click event leakage to underlying map.
    DeadMouseArea {
        anchors.fill: parent
    }

    QGCPalette { id: qgcPal }

    Component.onCompleted: {
        // Find and select the default page
        var targetUrl = globals.commingFromRIDIndicator
            ? "qrc:/qml/QGroundControl/AppSettings/RemoteIDSettings.qml"
            : "qrc:/qml/QGroundControl/AppSettings/GeneralSettings.qml"
        globals.commingFromRIDIndicator = false

        for (var i = 0; i < settingsPagesModel.count; i++) {
            var entry = settingsPagesModel.get(i)
            if (entry && entry.url === targetUrl) {
                _navigateTo(i, -1)
                break
            }
        }
    }

    Connections {
        target: rightPanel
        function onLoaded() {
            if (rightPanel.item && typeof rightPanel.item.sectionFilter !== "undefined") {
                rightPanel.item.sectionFilter = _selectedSectionIndex
            }
        }
    }

    SettingsPagesModel { id: settingsPagesModel }

    // Main layout using ColumnLayout + RowLayout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // === FULL-WIDTH HEADER ===
        Rectangle {
            id:                 headerBar
            Layout.fillWidth:   true
            Layout.preferredHeight: _headerHeight
            color:              qgcPal.window

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: _horizontalMargin
                anchors.rightMargin: _horizontalMargin
                spacing: _horizontalMargin

                QGCLabel {
                    text: qsTr("Settings")
                    font.pointSize: 18
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Button {
                    id:                 settingsCloseButton
                    objectName:         "toolbar_closeSettings"
                    Layout.alignment:  Qt.AlignVCenter
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 36
                    leftPadding:       0
                    rightPadding:      0
                    topPadding:        0
                    bottomPadding:     0
                    visible:           true
                    hoverEnabled:      true

                    background: Rectangle {
                        anchors.fill:   parent
                        color:          settingsCloseButton.hovered ? "#e74c3c" : "#c0392b"
                        radius:         6
                        border.width:   1
                        border.color:   "#ec7063"
                    }

                    contentItem: Row {
                        anchors.centerIn: parent
                        spacing:        6

                        QGCColoredImage {
                            height:                 16
                            width:                  height
                            fillMode:               Image.PreserveAspectFit
                            color:                  "white"
                            source:                 "/res/close.svg"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text:                   "Close"
                            color:                  "white"
                            font.pointSize:         12
                            font.bold:              true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    onClicked: {
                        toolDrawer.visible = false
                    }
                }
            }
        }

        // === CONTENT ROW: Sidebar + Main Content ===
        RowLayout {
            Layout.fillWidth:   true
            Layout.fillHeight:  true
            spacing: 0

            // === LEFT SIDEBAR ===
            Rectangle {
                id:                 sidebarContainer
                Layout.preferredWidth: _sidebarWidth
                Layout.fillHeight:   true
                Layout.minimumWidth:  200
                color:              qgcPal.window

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: _verticalMargin
                    spacing: _verticalMargin

                    // Search field
                    QGCTextField {
                        id:                 searchField
                        Layout.fillWidth:   true
                        Layout.preferredHeight: 36
                        placeholderText:    qsTr("Search settings...")
                        font.pointSize:     13

                        onTextChanged: {
                            settingsView._searchQuery = text
                        }
                    }

                    // Menu list with scroll
                    QGCFlickable {
                        id:                 buttonList
                        objectName:         "settings_buttonList"
                        Layout.fillWidth:   true
                        Layout.fillHeight:  true
                        contentHeight:      buttonColumn.height
                        flickableDirection:  Flickable.VerticalFlick
                        clip:               true

                        ColumnLayout {
                            id:         buttonColumn
                            width:      parent.width
                            spacing:    0

                            Repeater {
                                id:     buttonRepeater
                                model:  settingsPagesModel

                                ColumnLayout {
                                    id:     pageColumn
                                    width:  parent.width
                                    spacing: 0
                                    Layout.fillWidth: true

                                    required property int index
                                    required property var model

                                    property string pageName:    model.name ?? ""
                                    property string pageUrl:     model.url ?? ""
                                    property string pageIconUrl: model.iconUrl ?? ""
                                    property var    pageVisible: model.pageVisible ?? function() { return true }
                                    property var    pageSections: {
                                        try {
                                            var trStr = model.translatableTerms
                                            if (trStr && trStr !== "") {
                                                var trTerms = JSON.parse(trStr)
                                                return trTerms.map(function(t) {
                                                    if (!t.terms || t.terms.length === 0) return ""
                                                    return qsTranslate(t.context, t.terms[0])
                                                }).filter(function(s) { return s !== "" })
                                            }
                                            var s = model.sections
                                            return (s && s !== "") ? JSON.parse(s) : []
                                        } catch(e) {
                                            console.warn("AppSettings: JSON parse error in pageSections:", e)
                                            return []
                                        }
                                    }
                                    property bool isSelected: settingsView._selectedPageIndex === index
                                    property bool hasMultipleSections: pageSections.length > 1
                                    property bool isSearching: settingsView._searchQuery.trim() !== ""
                                    property bool matchesSearch: settingsView._pageMatchesSearch(index)
                                    property bool isExpanded: hasMultipleSections && (isSearching ? matchesSearch : settingsView._isExpanded(index))

                                    visible: {
                                        if (pageName === "Divider") return !isSearching
                                        if (!pageVisible()) return false
                                        if (isSearching) return matchesSearch
                                        return true
                                    }

                                    // Divider
                                    Item {
                                        Layout.fillWidth: true
                                        height: 8
                                        visible: pageName === "Divider"
                                    }

                                    // Page button
                                    SettingsButton {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        objectName:    "settingsButton_" + (model.nameKey ?? pageName)
                                        text:          pageName
                                        icon.source:   pageIconUrl
                                        expandable:    hasMultipleSections
                                        expanded:      isExpanded
                                        checked:       isSelected && settingsView._selectedSectionIndex === -1
                                        visible:       pageName !== "Divider" && pageVisible()

                                        onClicked: {
                                            if (mainWindow.allowViewSwitch()) {
                                                settingsView._navigateTo(index, -1)
                                                if (hasMultipleSections) {
                                                    // Toggle expand/collapse when re-clicking the same page
                                                    if (isSelected && isExpanded) {
                                                        settingsView._setExpanded(index, false)
                                                    } else if (!isExpanded) {
                                                        settingsView._setExpanded(index, true)
                                                    }
                                                }
                                            }
                                        }

                                        onToggleExpand: {
                                            if (!mainWindow.allowViewSwitch()) {
                                                return
                                            }
                                            var expanding = !isExpanded
                                            settingsView._setExpanded(index, expanding)
                                            if (!expanding && isSelected) {
                                                settingsView._navigateTo(index, -1)
                                            }
                                        }
                                    }

                                    // Section sub-items (indented, shown when page is expanded)
                                    Repeater {
                                        model: isExpanded ? pageSections : []

                                        Button {
                                            id:             sectionBtn
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 36
                                            leftPadding:    24
                                            hoverEnabled:   !ScreenTools.isMobile

                                            property int sectionIndex: index
                                            property bool sectionChecked: pageColumn.isSelected && settingsView._selectedSectionIndex === sectionIndex
                                            property bool sectionMatchesSearch: {
                                                if (!pageColumn.isSearching) return true
                                                var matches = settingsView._matchingSections(pageColumn.index)
                                                return matches.indexOf(sectionIndex) !== -1
                                            }
                                            property bool sectionContentVisible: {
                                                if (!pageColumn.isSelected) return true
                                                if (!rightPanel.item) return true
                                                if (typeof rightPanel.item.sectionVisible !== "function") return true
                                                return rightPanel.item.sectionVisible(sectionIndex)
                                            }
                                            property color textColor: sectionChecked || pressed ? qgcPal.buttonHighlightText : qgcPal.buttonText
                                            visible: sectionMatchesSearch && sectionContentVisible

                                            background: Rectangle {
                                                color:   qgcPal.buttonHighlight
                                                opacity: sectionBtn.sectionChecked || sectionBtn.pressed ? 1 : sectionBtn.enabled && sectionBtn.hovered ? 0.2 : 0
                                                radius:  4
                                            }

                                            contentItem: QGCLabel {
                                                text:  modelData
                                                color: sectionBtn.textColor
                                                font.pointSize: 13
                                                horizontalAlignment: Text.AlignLeft
                                            }

                                            onClicked: {
                                                if (mainWindow.allowViewSwitch()) {
                                                    settingsView._navigateTo(pageColumn.index, sectionIndex)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Vertical divider
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: qgcPal.windowShade
            }

            // === RIGHT CONTENT PANEL ===
            Rectangle {
                id:                 contentContainer
                Layout.fillWidth:   true
                Layout.fillHeight:  true
                color:             qgcPal.window

                // ScrollView to handle overflow in content pages
                ScrollView {
                    id:                 contentScrollView
                    anchors.fill:       parent
                    anchors.margins:    _horizontalMargin
                    clip:               true
                    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                    ScrollBar.vertical:   ScrollBar.AsNeeded

                    //-- Panel Contents
                    Loader {
                        id:                     rightPanel
                        objectName:             "settings_rightPanel"
                        width:                  contentScrollView.availableWidth
                        height:                 contentScrollView.availableHeight
                    }
                }
            }
        }
    }
}
