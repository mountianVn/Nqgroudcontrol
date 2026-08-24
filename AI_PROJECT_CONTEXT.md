# AI Project Context: NGroundControl HTI

This document is the handoff for work on the current source tree. It describes the source as inspected on 2026-08-25. If it conflicts with source code, source code wins.

## 1. Project Overview

- **Base project:** QGroundControl v5.1.0.
- **Custom project:** HTI, branded at build time as `NGroundControl`.
- **Current platform:** Windows x64.
- **Stack:** C++20, Qt 6/QML, CMake, Ninja, MSVC 2022, GStreamer.
- **Custom goal:** Replace the stock Fly View presentation with an HTI operational UI, add Vietnamese localization/log interpretation, and provide offline recorded WAV alerts while reusing QGC vehicle and map backends.

Primary additions are the HTI Fly View overlay, function/mission panels, telemetry HUD/gauges, Vietnamese catalogs, firmware-message translation, WAV voice alerts, a custom Fly View vehicle marker, and project change records.

## 2. Current Build Environment

| Field | Current value | Evidence |
|---|---|---|
| Repository path | `C:\Users\ADMIN\Desktop\QG\qgroundcontrol` | Current workspace |
| Current branch | `feature/flyview-customization` | `git branch --show-current` |
| GitHub remote | `github-user` -> `https://github.com/mountianVn/Nqgroudcontrol.git` | `git remote -v` |
| Main Qt Creator build directory | `C:\Users\ADMIN\Desktop\QG\qgroundcontrol\build\hti` | `.qtcreator/CMakeLists.txt.user` / cache |
| Main build type | `Release` | `build/hti/CMakeCache.txt` |
| Main executable | `build\hti\Release\NGroundControl.exe` | Present; last inspected 2026-08-24 |
| Generator | Ninja: `C:\Qt\Tools\Ninja\ninja.exe` | CMake cache |
| CMake | 3.30.5 | `cmake --version` |
| Qt | 6.11.1, `C:\Qt\6.11.1\msvc2022_64` | CMake cache / build config |
| Compiler | MSVC 19.44.35228 / VS 2022 Community | CMake cache |
| GStreamer | `C:\gstreamer-msvc-x86_64-clean`, configured 1.28.x | CMake cache |
| Custom overlay selection | `QGC_CUSTOM_DIR=custom/HTI` | CMake cache |
| Verified Debug build | `build\hti-debug-marker\Debug\NGroundControl.exe` | HTI Debug link passed during marker work; this tree is ignored and not the normal Qt Creator build |

The active Qt Creator project file is `.qtcreator/CMakeLists.txt.user`. It currently describes a Release/Ninja/C++20 configuration using `build\hti`. Do not copy any `build/` folder to another workstation.

### Current command forms

Run the following from a Visual Studio 2022 developer shell, or let Qt Creator provide the MSVC environment:

```powershell
cmake -S . -B build/hti -G Ninja `
  -DCMAKE_BUILD_TYPE=Release `
  -DQGC_CUSTOM_DIR=custom/HTI `
  -DCMAKE_CXX_STANDARD=20 `
  -DCMAKE_CXX_STANDARD_REQUIRED=ON `
  -DCMAKE_PREFIX_PATH=C:/Qt/6.11.1/msvc2022_64

cmake --build build/hti --target NGroundControl
```

For an isolated Debug build, use a different directory such as `build/hti-debug`, set `-DCMAKE_BUILD_TYPE=Debug`, and preserve `-DQGC_CUSTOM_DIR=custom/HTI`.

## 3. Focused Project Structure

```text
custom/HTI/
├── CMakeLists.txt                 # Adds HTI sources, Qt Multimedia, resources, generated WAV QRC
├── cmake/CustomOverrides.cmake    # Branding: NGroundControl application metadata
├── CustomPlugin.{h,cc}            # QGC custom plugin, QML URL interceptor, voice manager exposure
├── CustomOptions.{h,cc}           # QGCOptions/FlyView options hook
├── resources.qrc                  # HTI QML, QML overrides, aircraft image resource
├── images/
│   └── aircraft_marker.png        # Transparent Fly View marker image, nose points up
├── qml/
│   ├── FlyViewCustomLayer.qml     # HTI overlay root inserted by FlyView
│   ├── HTILeftToolBar.qml         # Left vertical toolbar
│   ├── HTIRightControlPanel.qml   # Right Functions/Mission panel shell
│   ├── HTIFunctionsPanel.qml      # Guided actions, telemetry, messages/log popup
│   ├── HTIMissionPanel.qml        # Compact mission information/actions
│   ├── HTIBottomRightHud.qml      # Distance/time pills and flight gauges
│   ├── HTI*Gauge.qml              # Speed/altitude, attitude, heading rendering
│   ├── HTI*Button.qml             # Shared HTI button/tab/status components
│   ├── HTIConnectionDialog.qml    # Manual connection popup
│   ├── HTIMavlinkActionsPanel.qml # QGC JSON-defined actions surface
│   ├── HTIVoiceSettings.qml       # Settings page for recorded voice controls
│   └── QGroundControl/
│       ├── MainWindow.qml         # Settings navigation override
│       ├── Controls/AppSettings.qml
│       ├── FlyView/*.qml          # Removes/repositions stock Fly View UI elements
│       └── FlightMap/MapItems/VehicleMapItem.qml
│                                   # Fly View custom aircraft visual override
├── Voice/
│   ├── HTIVoiceManager.{h,cc}     # Offline event/WAV/audio/state implementation
│   ├── wav_output/                # 139 tracked Vietnamese/English WAV assets
│   └── DANH_SACH_*.csv            # UTF-8 BOM recording/reference lists
└── lich_su_thay_doi.csv           # HTI-local change record

translations/
├── qgc_source_vi_VN.ts            # Source/QML/C++ Vietnamese catalog
└── qgc_json_vi_VN.ts              # JSON settings/mission Vietnamese catalog

src/Utilities/Audio/AudioOutput.{h,cc}
                                    # Minimal core patch for core speech suppression
lich_su_thay_doi.csv                # Root project change record
MO_TA_CHUC_NANG_CAI_TIEN.md         # User-facing improvement summary
```

## 4. Modifications Summary

### A. HTI Custom Plugin

**Purpose:** activate HTI branding, QML overrides, custom UI imports, the HTI voice manager, and Vietnamese core-speech suppression.

**Files:** `custom/HTI/CustomPlugin.{h,cc}`, `CustomOptions.{h,cc}`, `cmake/CustomOverrides.cmake`, `CMakeLists.txt`.

**Current behavior:** `CustomPlugin` is the QGC custom class. It creates `HTIVoiceManager`, exposes it as QML context property `htiVoiceManager`, adds `qrc:/qml/HTI` as an import path, and registers `CustomOverrideInterceptor`. The interceptor redirects an original `qrc:` QML URL to `:/Custom<url-path>` when the HTI resource exists.

**Backend/API used:** `QGCCorePlugin`, `QQmlApplicationEngine`, `QQmlAbstractUrlInterceptor`, `QGCApplication::languageChanged`.

**Important details:** `CustomOverrides.cmake` changes app branding to `NGroundControl`; `QGC_CUSTOM_DIR` must be `custom/HTI`. Use the existing interceptor instead of patching more core QML files.

**Do not break:** URL interception, the `htiVoiceManager` context property, or the custom build definition (`CUSTOMHEADER=CustomPlugin.h`, `CUSTOMCLASS=CustomPlugin`).

### B. Fly View Overlay, Left Toolbar, and Top Area

**Purpose:** put HTI controls above the QGC Fly View map/video without resizing its underlying surface.

**Files:** `qml/FlyViewCustomLayer.qml`, `HTILeftToolBar.qml`, `HTILeftToolButton.qml`, `HTIConnectionDialog.qml`, `qml/QGroundControl/FlyView/FlyViewTopRightColumnLayout.qml`.

**Current behavior:** `FlyViewCustomLayer` instantiates `HTILeftToolBar`, `HTIRightControlPanel`, `HTIBottomRightHud`, `HTIMavlinkActionsPanel`, a manual connection dialog, and QGC `PhotoVideoControl`. Toolbar actions reuse QGC settings/map/zoom properties and guard map access. The stock top-right layout is reduced to `TerrainProgress`; photo/video control is deliberately placed in the HTI overlay.

**Backend/API used:** `QGroundControl.multiVehicleManager.activeVehicle`, `mainWindow.showSettingsTool`, `mapControl.zoomLevel`, `QGCToolInsets`, `PhotoVideoControl`.

**Known limitations:** actual visual interaction at every desktop resolution has not been replayed after the latest source changes.

**Do not break:** `QGCToolInsets`, top-most z ordering, or the null-safe `activeVehicle` checks.

### C. Right Control Panel and Guided Actions

**Purpose:** compact operational controls and telemetry on the right of Fly View.

**Files:** `HTIRightControlPanel.qml`, `HTIFunctionsPanel.qml`, `HTIMissionPanel.qml`, `HTIMavlinkActionsPanel.qml`, shared button/status components.

**Current behavior:** Functions supports mode selection (`Auto`, `Loiter`, `QLoiter` where exposed), start mission, current waypoint selection, guided altitude change, RTL, guided land, preflight display, telemetry and an expanded vehicle-message popup. Mission tab shows compact mission status; selecting the tab also calls `mainWindow.showPlanView()`.

**Backend/API used:** `Vehicle.flightMode`, `flightModes`, `startMission()`, `setCurrentMissionSequence()`, `guidedModeChangeAltitude()`, `guidedModeRTL(false)`, `guidedModeLand()`, `readyToFly`, `allSensorsHealthy`, Facts and battery FactGroups.

**Important details:** firmware-specific mission behavior is delegated to QGC through `Vehicle.startMission()`, not reimplemented. FunctionPanel keeps its own MAVLink formatted-message history, seeded from `formattedMessages` and appended via `newFormattedMessage`.

**Do not break:** direct calls to QGC Vehicle API, dynamic facts, or message-log accumulation.

### D. Bottom Right HUD and Gauges

**Purpose:** show time, Home distance, total distance, waypoint distance and compact instruments.

**Files:** `HTIBottomRightHud.qml`, `HTIInfoPill.qml`, `HTISpeedAltitudeGauge.qml`, `HTISpeedGauge.qml`, `HTIAltitudeGauge.qml`, `HTIAttitudeGauge.qml`, `HTIHeadingGauge.qml`.

**Current behavior:** HUD reads vehicle Facts/properties through a local null/NaN normalization helper. It formats metric distances, flight time, altitude/climb rate, speed, roll, pitch and heading. Stock `FlyViewBottomRightRowLayout.qml` is overridden as a zero-size invisible item so it does not compete with the HTI HUD.

**Backend/API used:** `flightTime`, `distanceToHome`, `flightDistance`, `distanceToNextWP`, `missionItemIndex`, `altitudeRelative`, `climbRate`, `groundSpeed`, `roll`, `pitch`, `heading`.

**Do not break:** responsive width calculation, bottom-right anchoring, and `FlyViewWidgetLayer` inset interface properties on the stock-layout override.

### E. Settings and Localization

**Purpose:** Vietnamese UI/mission settings and HTI Voice settings through QGC settings navigation.

**Files:** `translations/qgc_source_vi_VN.ts`, `translations/qgc_json_vi_VN.ts`, `qml/QGroundControl/MainWindow.qml`, `qml/QGroundControl/Controls/AppSettings.qml`, `HTIVoiceSettings.qml`.

**Current behavior:** QGC's current language catalog is used for normal UI translation. Custom QML uses `qsTr`. `MainWindow.qml` opens the HTI AppSettings override; that override exposes the HTI Voice page. QML/C++ source catalog includes custom HTI text and normalized UAV wording.

**Backend/API used:** `QGCApplication::languageChanged`, standard QGC translation loader/catalog mechanism, `QSettings` through voice manager.

**Known limitations:** `.qm` generation is build-time; after catalog edits, rebuild/lrelease must run. This source tree does not prove every Vietnamese string has been visually reviewed on all views.

**Do not break:** use `qsTr` for custom visible text; do not add an independent language selector or hard-coded if/else translations.

### F. Offline Voice/WAV System

**Purpose:** controlled Vietnamese/English recorded audio announcements without cloud TTS.

**Files:** `Voice/HTIVoiceManager.{h,cc}`, `Voice/wav_output/`, `HTIVoiceSettings.qml`, `CMakeLists.txt`.

**Current behavior:** CMake globs `wav_output/*.wav`, writes a generated QRC and adds it to `QGC_RESOURCES`. `HTIVoiceManager` uses `QMediaPlayer` + `QAudioOutput` at `1.20x`, resource URLs, an audio queue, critical interruption, event cooldowns and user group toggles stored in `QSettings` group `HTIVoice`.

Static Vietnamese event WAVs cover connection, arm state, modes, mission, GPS/RTK, battery, PreArm, safety and camera patterns. Recognized `Vehicle::textMessageReceived` messages are mapped; arbitrary STATUSTEXT is not blindly spoken. Dynamic phrase composition uses number/unit WAV files for battery, altitude and distances.

**Language behavior:** the custom static pack plays only when UI locale is Vietnamese. Dynamic sequence composition supports Vietnamese and English number assets. In English, QGC core speech is re-enabled; in Vietnamese it is suppressed by the core patch described below.

**Telemetry cadence:**

- Battery: announces current remaining percentage after a decrease of at least 5 percentage points from the voice baseline; low/critical alerts remain separate.
- Total flight distance (`flightDistance`): announces every additional 3 km.
- Distance to Home (`distanceToHome`): announces on 1 km boundary changes in either direction; while returning below 1 km, announces descending 100 m boundaries.
- Relative altitude: 100 m boundaries in general; descending 10 m boundaries below 50 m; repeated while audio is idle from 1 to under 10 m; once only below 1 m; state resets at zero, disarm, re-arm, invalid altitude or vehicle change.
- Altitude/distance below 1 km use integer meters; altitude meter fractions are truncated.

**Do not break:** no cloud TTS, no direct MAVLink/Vehicle backend changes, language switching stop/clear behavior, cooldown/priority semantics, or CMake's generated WAV QRC.

### G. Fly View Aircraft Marker

**Purpose:** use `aircraft_marker.png` instead of the default Fly View vehicle image while retaining QGC coordinate and heading behavior.

**Files:** `images/aircraft_marker.png`, `resources.qrc`, `qml/QGroundControl/FlightMap/MapItems/VehicleMapItem.qml`.

**Current behavior:** the interceptor overrides QGC `VehicleMapItem.qml`. On Fly View it selects `qrc:/HTI/images/aircraft_marker.png`; on Plan View (`map.planView`) it retains `vehicle.vehicleImageOpaque`. Marker controls are `aircraftMarkerSize: 52` and `aircraftMarkerScale: 1.0`. Image is square, centered, `Image.PreserveAspectFit`, no added Rectangle/background/shadow.

**Rotation:** source image nose points up. The source keeps the original semantic binding exactly: `angle: isNaN(_root.heading) ? 0 : _root.heading`, with rotation origin at icon center. No map bearing term was added.

**Do not break:** `MapQuickItem.coordinate`, anchor point, existing gimbal azimuth Canvas, active/multi-vehicle opacity, vehicle label, heading rotation, or Plan View fallback.

### H. Other Resources and Test Surface

`HTITestPanel.qml` is exposed through `CustomPlugin::analyzePages()` as `NGroundControl Test Panel`. `resources.qrc` also contains HTI image/gauge assets and all URL overrides. Recording-list CSVs are operational reference documents, not runtime inputs.

## 5. File-by-File Map

| File | Purpose | Key classes/components | Dependencies | Notes |
|---|---|---|---|---|
| `custom/HTI/CMakeLists.txt` | HTI build overlay and WAV QRC generator | `CUSTOM_SOURCES`, `QGC_RESOURCES` | CMake, Qt Multimedia | Do not replace generated WAV QRC with a static partial list. |
| `custom/HTI/cmake/CustomOverrides.cmake` | Application branding | `QGC_APP_*` cache variables | Root CMake custom include | Must load before `project()`. |
| `custom/HTI/CustomPlugin.{h,cc}` | Plugin/bootstrap/interceptor | `CustomPlugin`, `CustomOverrideInterceptor` | `QGCCorePlugin`, QML engine, `AudioOutput` | Owns `htiVoiceManager` QML context property. |
| `custom/HTI/CustomOptions.{h,cc}` | Fly View options hook | `CustomOptions`, `CustomFlyViewOptions` | `QGCOptions` | Kept deliberately minimal. |
| `custom/HTI/resources.qrc` | HTI resource registry | QML/assets/overrides | Qt RCC | Required for all custom QML and marker PNG. |
| `custom/HTI/qml/FlyViewCustomLayer.qml` | HTI Fly View overlay root | toolbar/panels/HUD | QGC FlyView/FlightMap | Must preserve tool insets and z ordering. |
| `custom/HTI/qml/HTIFunctionsPanel.qml` | Operations and telemetry/log UI | guided actions, log translation | `Vehicle` QML API/Facts | Uses local formatted-message history. |
| `custom/HTI/qml/HTIRightControlPanel.qml` | Right panel/tab container | Functions, Mission loader | QML layouts | Width is responsive, not fixed. |
| `custom/HTI/qml/HTIBottomRightHud.qml` | Telemetry/gauge cluster | info pills/gauges | `Vehicle` Facts | Null-safe `_factValue` boundary. |
| `custom/HTI/qml/HTI*Gauge.qml` | Instrument graphics | speed/altitude/attitude/heading | QML values from HUD | Visual-only. |
| `custom/HTI/qml/HTIVoiceSettings.qml` | Voice settings page | `htiVoiceManager` bindings | QSettings via manager | Test button is disabled outside Vietnamese active pack state. |
| `custom/HTI/qml/QGroundControl/MainWindow.qml` | Settings navigation override | `showSettingsTool` | Stock MainWindow API | Routes settings to custom AppSettings QRC. |
| `custom/HTI/qml/QGroundControl/Controls/AppSettings.qml` | Custom settings page routing | `HTIVoiceSettings` loader | QGC Settings UI | Override, not a new settings backend. |
| `custom/HTI/qml/QGroundControl/FlyView/*.qml` | Stock Fly View visual suppression/reposition | layout interfaces | FlyViewWidgetLayer | Keep interface properties expected by QGC. |
| `custom/HTI/qml/QGroundControl/FlightMap/MapItems/VehicleMapItem.qml` | FlyView aircraft visual override | `MapQuickItem`, `Image`, `Rotation` | QGC FlightMap marker logic | Plan View deliberately uses stock image. |
| `custom/HTI/Voice/HTIVoiceManager.{h,cc}` | Offline audio/event/state engine | `HTIVoiceManager` | `Vehicle`, `MultiVehicleManager`, Facts, Qt Multimedia | Main custom backend module. |
| `custom/HTI/Voice/wav_output/` | Recorded audio assets | 139 WAV files | Generated QRC | Asset changes require configure/build to refresh glob. |
| `translations/qgc_source_vi_VN.ts` | Source/custom Vietnamese translations | Qt TS catalog | `lupdate`/`lrelease` | Includes HTI source strings. |
| `translations/qgc_json_vi_VN.ts` | JSON configuration translations | Qt TS catalog | JSON translation tooling | Mission/settings localization. |
| `src/Utilities/Audio/AudioOutput.{h,cc}` | **CORE PATCH**: core TTS suppression | `setSpeechSuppressed` | `QTextToSpeech` | Needed so stock English speech does not overlap HTI Vietnamese WAV. |
| `custom/HTI/lich_su_thay_doi.csv`, `lich_su_thay_doi.csv` | Change records | CSV history | Documentation process | Update after significant changes. |

## 6. Data Flow / Architecture

### Fly View UI

```text
src/FlyView/FlyView.qml
  -> FlyViewCustomLayer (URL intercepted to custom/HTI/qml/FlyViewCustomLayer.qml)
      -> HTILeftToolBar
      -> HTIRightControlPanel -> HTIFunctionsPanel / HTIMissionPanel
      -> HTIBottomRightHud -> gauges + info pills
      -> HTIMavlinkActionsPanel / PhotoVideoControl
```

### Vehicle map marker

```text
MultiVehicleManager.vehicles
  -> FlyViewMap.qml MapItemView delegate VehicleMapItem
  -> CustomOverrideInterceptor
  -> custom VehicleMapItem.qml
  -> MapQuickItem.coordinate (unchanged)
  -> Image aircraft_marker.png on Fly View
  -> Rotation(vehicle.heading.value), origin at icon center
```

### Telemetry

```text
MAVLink messages
  -> QGC Vehicle / FactGroups
  -> activeVehicle Facts and QML properties
  -> HTIFunctionsPanel / HTIBottomRightHud
  -> status rows, pills, gauges, message popup
```

### Voice

```text
Vehicle signals / MAVLink STATUSTEXT / Fact polling
  -> HTIVoiceManager
  -> controlled event or phrase mapping
  -> cooldown / priority / queue / language gate
  -> QMediaPlayer + QAudioOutput (1.20x)
  -> qrc:/HTI/Voice/wav/<asset>.wav
```

### Language and core speech

```text
QGCApplication.languageChanged
  -> CustomPlugin::_syncCoreSpeechForLanguage
  -> AudioOutput::setSpeechSuppressed(Vietnamese)
  -> HTIVoiceManager::_updateLanguage
  -> stop/clear custom audio and use the matching language behavior
```

## 7. QML Component Relationships

```text
FlyView
└── FlyViewCustomLayer (HTI override)
    ├── PhotoVideoControl
    ├── HTILeftToolBar
    │   └── HTILeftToolButton x6
    ├── HTIRightControlPanel
    │   ├── HTIPanelTabButton x2
    │   └── Loader
    │       ├── HTIFunctionsPanel
    │       │   ├── HTIModernButton / HTIActionButton
    │       │   ├── HTIStatusRow
    │       │   └── Vehicle-message Popup
    │       └── HTIMissionPanel
    ├── HTIMavlinkActionsPanel
    └── HTIBottomRightHud
        ├── HTIInfoPill x4
        ├── HTISpeedAltitudeGauge
        ├── HTIAttitudeGauge
        └── HTIHeadingGauge

AppSettings override
└── HTIVoiceSettings
    └── htiVoiceManager

FlyViewMap MapItemView
└── VehicleMapItem (HTI visual override only on Fly View)
```

## 8. Backend Dependencies

| Backend | Used in | Signals/properties reused | Core patch? |
|---|---|---|---|
| `Vehicle` | Functions, HUD, Voice | guided API, flight mode, coordinate, Facts, messages | No |
| `MultiVehicleManager` | Overlay, HUD, Voice | `activeVehicle`, `vehicles`, `vehicleAdded`, `vehicleRemoved`, `activeVehicleChanged` | No |
| `Fact` / `FactGroup` | HUD, Voice, Functions | raw values for GPS, battery, altitude, distance | No |
| Battery FactGroup model | Functions, Voice | `percentRemaining`, voltage/current/consumption/time | No |
| `Vehicle` signals | Voice | `armedChanged`, `flightModeChanged`, `flyingChanged`, `landingChanged`, `prearmErrorChanged`, `textMessageReceived` | No |
| MAVLink STATUSTEXT | Functions, Voice | formatted messages and `textMessageReceived` | No protocol change |
| `AudioOutput` | CustomPlugin language policy | `setSpeechSuppressed` | **Yes**; minimal core patch |
| `QGCApplication` | Plugin, Voice | `languageChanged`, `getCurrentLanguage()` | No |
| `SettingsManager` / `QSettings` | UI / Voice | QGC settings navigation; `HTIVoice/*` persistent keys | No |
| `VideoManager` | No direct HTI backend modification | PhotoVideoControl reused only | No |
| `LinkManager` | No direct HTI backend modification | Connection UI delegates to QGC UI | No |

## 9. UI Design Rules

### Visual conventions

- Dark translucent blue/black panels, e.g. `#D908111A`, `#B30A1722`, `#B30D1722`.
- Cyan/blue borders: `#35D7FF`, `#31C8FF`, `#47A7FF`, `#2C7188`.
- Green healthy/active: `#63F29A`, `#39D98A`, `#68d783`.
- Warning/yellow: `#F4D35E`, `#ffe04b`; danger/red: `#FF5A52`, `#eb5d5d`.
- Text is generally light `#F4F8FB` / `#d7e0e8`; headings use green/cyan accent and DemiBold.
- Buttons use HTI shared button components and explicit variants (`primary`, `secondary`, `blue`, `danger`, etc.).
- Panels commonly use 7-20 px rounded corners depending on scale; avoid new visual styles that conflict with this glass operational UI.

### Layout rules

- HTI controls are overlays. Do not resize the underlying Fly View map/video to create room.
- Use anchors, `Layout.*`, `ScreenTools` dimensions and bounded calculations; avoid new fixed absolute coordinates unless an existing overlay requires a deliberate offset.
- Keep the right panel height constrained above the bottom HUD.
- Preserve `QGCToolInsets` and stock override interface properties so QGC does not place controls over HTI UI.
- Avoid strong shadows/background rectangles behind the aircraft image.
- Custom map markers should use a fixed square bounding box and centered rotation.

## 10. Important Project Rules

1. Target is QGroundControl v5.1.0. Do not use an upstream master API without verifying it exists here.
2. Prefer changes under `custom/HTI`; use the URL interceptor/resources before patching core QML.
3. Reuse `Vehicle`, Facts, `MultiVehicleManager`, existing guided APIs and QGC settings. Do not duplicate MAVLink, Vehicle or LinkManager logic.
4. Keep `activeVehicle` and Fact access null-safe.
5. Core patches must be minimal and documented. Currently only `AudioOutput` is patched for language-dependent speech suppression.
6. Do not refactor unrelated QGC modules while implementing HTI UI/voice work.
7. Custom visible QML text must use `qsTr`; C++ visible text uses `tr`.
8. For voice, keep WAV offline behavior, controlled STATUSTEXT mapping, queue priority and anti-spam state.
9. After a significant change, build an HTI Debug target where possible, inspect QML errors, run `git diff --check`, and update both change-history CSV files.
10. Update this document only in sections affected by important architecture/build/behavior changes; do not rewrite it unnecessarily.

## 11. Current Working Features

- [PASS] HTI custom CMake overlay and NGroundControl branding are configured.
- [PASS] Fly View custom overlay, toolbar, right panel, bottom HUD and gauges exist in resources.
- [PASS] Right-side guided actions reuse QGC Vehicle APIs.
- [PASS] FunctionPanel keeps independent formatted MAVLink message history and translates recognized firmware templates.
- [PASS] Vietnamese Qt TS catalogs exist; custom visible QML uses translation calls.
- [PASS] HTI WAV manager compiles and all 139 WAV assets are generated into the QRC at configure time.
- [PASS] Core English speech suppression for Vietnamese UI is implemented through `AudioOutput`.
- [PASS] Dynamic voice cadence code for battery, Home/total distance and altitude is present and compiled.
- [PASS] Fly View aircraft marker override is resource-packaged; QML lint has zero errors and HTI Debug executable linked successfully.
- [PASS] Marker rotation preserves original heading binding and center origin in source.
- [PARTIAL] Voice language settings UI presents a fixed Vietnamese pack even though dynamic English WAV composition exists.
- [NOT TESTED] Latest marker/voice behavior with a live connected vehicle, real heading changes, map bearing changes, and multiple vehicles.
- [NOT TESTED] Full end-to-end listener verification for every WAV and all firmware STATUSTEXT variants.

## 12. Known Issues

### Issue: marker behavior is source/build verified, not flight-tested

- **Affected files:** `custom/HTI/qml/QGroundControl/FlightMap/MapItems/VehicleMapItem.qml`.
- **Observed behavior:** no live-vehicle rotation/map-pan/map-bearing test result is stored in source or history.
- **Suspected cause:** a physical/simulated vehicle heading scenario was not run in the available session.
- **Current workaround:** source keeps the original `vehicle.heading.value` rotation binding; use the manual marker checklist below after any marker change.
- **Next action:** test heading 0/90/180/270, zoom, pan, map rotation, disconnect/reconnect and multi-vehicle selection.

### Issue: legacy QML lint warnings remain in the copied marker component

- **Affected files:** custom `VehicleMapItem.qml`.
- **Observed behavior:** `qmllint` reports 21 unqualified-access warnings and 0 errors; the source component reports 25 similar warnings.
- **Suspected cause:** the QGC component uses `Repeater` delegate context, `object`, IDs and Canvas patterns that static lint cannot fully qualify.
- **Current workaround:** new marker bindings are qualified with `_root` where practical; no suppression or behavior rewrite was added.
- **Next action:** only reduce warnings if a behavior-preserving QML change can be validated against Fly View/gimbal behavior.

### Issue: unused legacy voice asset remains

- **Affected files:** `custom/HTI/Voice/wav_output/vi_le.wav` and recording CSV.
- **Observed behavior:** the number composer no longer appends `vi_le.wav`, by deliberate Vietnamese wording change.
- **Suspected cause:** asset/reference list predates the wording decision.
- **Current workaround:** harmlessly packaged asset remains in generated QRC.
- **Next action:** remove or relabel it only after updating all recording lists and validating no external workflow depends on that filename.

### Issue: tracked temporary builder exists in history

- **Affected file:** `.tmp_distance_voice_csv/build_distance_voice_csv.mjs`.
- **Observed behavior:** it is tracked by the branch history but is not runtime code.
- **Suspected cause:** an earlier CSV-generation helper was committed with the voice asset work.
- **Current workaround:** runtime ignores it; `build/` and temporary node modules are ignored.
- **Next action:** remove it in a dedicated cleanup commit if no recording workflow needs it.

## 13. Build and Run Guide

### Qt Creator

1. Open root `CMakeLists.txt`.
2. Select `Desktop Qt 6.11.1 MSVC2022 64bit`.
3. Use build directory `build\hti`.
4. Ensure CMake parameters include `QGC_CUSTOM_DIR=custom/HTI`, Ninja, C++20 and the Qt prefix listed in section 2.
5. Run CMake, select target `NGroundControl`, choose Release or a separate Debug build directory, then Build/Run.

### Command line

Use a VS 2022 developer shell. Do not configure into a copied or stale build directory with another generator.

```powershell
cmake -S . -B build/hti-debug -G Ninja `
  -DCMAKE_BUILD_TYPE=Debug `
  -DQGC_CUSTOM_DIR=custom/HTI `
  -DCMAKE_CXX_STANDARD=20 `
  -DCMAKE_CXX_STANDARD_REQUIRED=ON `
  -DCMAKE_PREFIX_PATH=C:/Qt/6.11.1/msvc2022_64

cmake --build build/hti-debug --target NGroundControl
.
build\hti-debug\Debug\NGroundControl.exe
```

For the current main release build:

```powershell
cmake --build build/hti --target NGroundControl
.\build\hti\Release\NGroundControl.exe
```

If link fails with `LNK1168`, close the currently running executable that holds the target file. If changing WAV files, rerun CMake/build so `file(GLOB ... CONFIGURE_DEPENDS)` regenerates the WAV QRC.

## 14. Test Checklist

- [ ] App startup; no fatal QML error.
- [ ] Connect/disconnect a vehicle.
- [ ] Fly View map loads; pan and zoom remain responsive.
- [ ] Aircraft marker appears with no background; marker stays centered at coordinate.
- [ ] Heading: 0 up/North, 90 right/East, 180 down/South, 270 left/West.
- [ ] Map bearing rotation does not introduce double vehicle rotation.
- [ ] Active/non-active vehicle opacity and multi-vehicle label remain correct.
- [ ] Left toolbar: connect, maps, zoom, screen, settings.
- [ ] Right controls: mission start, guided altitude, RTL, guided land, mode buttons.
- [ ] MAVLink message popup retains history after stock message view changes.
- [ ] Telemetry/HUD Facts update with vehicle data.
- [ ] Settings: English/Vietnamese switch and HTI Voice page persist settings.
- [ ] Voice: connect/disconnect, ARM/DISARM, mode, GPS, battery, PreArm, Home/total distance and landing altitude cadence.
- [ ] Build target `NGroundControl` in chosen Debug/Release configuration.

## 15. Change History Summary

| Date/phase | Major changes | Important fixes | Regression risk |
|---|---|---|---|
| 2026-08-09 to 2026-08-21 | HTI plugin, branding, Fly View overlay, toolbar, right panel, HUD/gauges, FunctionPanel log work and initial Vietnamese localization. | Responsive settings/Fly View work and MAVLink log continuity. | Overlay/inset conflicts; catalog completeness. |
| 2026-08-22 | Expanded Vietnamese terminology/settings/mission translations; introduced offline WAV voice assets/manager and settings; fixed IDE C++ code model. | Replaced TTS with WAV, audio overlap control, full WAV mapping, voice recording lists. | Language switching and WAV resource packaging. |
| 2026-08-22 to 2026-08-23 | Added dynamic altitude/distance/battery announcements, language gating, speed/playback improvements, Home/total distance cadence and final-approach altitude behavior. | C3495 build fix, voice anti-spam, meter units, removed Vietnamese filler-word playback, Qt Creator build configuration alignment. | Voice state transitions require live vehicle validation. |
| 2026-08-23 | Added custom aircraft marker through HTI QML resource override. | Kept Plan View stock icon; resource/QML Debug build verification. | Live heading/map-bearing/multi-vehicle visual test remains outstanding. |

Read the two CSV history files for precise individual entries; do not treat them as a substitute for current source.

## 16. Current Task / Next Steps

**CURRENT TASK: NONE.**

Recommended next steps:

1. Perform the live/simulated map-marker checklist and record actual heading/bearing results.
2. Exercise all voice cadence rules with a vehicle or test Fact source; capture missing or overly frequent announcements.
3. Decide whether to expose `aircraftMarkerSize`/scale in a persistent HTI setting instead of editing QML.
4. Clean up the tracked temporary CSV builder and unused `vi_le.wav` only in a focused, reviewed cleanup task.
5. Generate/review Vietnamese `.qm` output after the next translation catalog edit.

## 17. AI Quick Start

# AI QUICK START

- This is QGroundControl v5.1.0 customized as HTI/NGroundControl for Windows.
- Read this file first, then inspect current source; source code wins over documentation.
- Primary custom code is under `custom/HTI`; do not start by editing `src/`.
- Build overlay is selected by `-DQGC_CUSTOM_DIR=custom/HTI`.
- Main normal build is `build/hti`, currently Release/Ninja/C++20; executable is `build/hti/Release/NGroundControl.exe`.
- `CustomPlugin` installs the QML URL interceptor and exposes `htiVoiceManager`.
- `FlyViewCustomLayer.qml` owns HTI Fly View overlay UI.
- `HTIFunctionsPanel.qml` is the guided control/telemetry/log surface.
- `HTIBottomRightHud.qml` owns compact telemetry and gauges.
- `HTIVoiceManager` owns WAV mapping, queueing, telemetry cadence and language policy.
- WAV assets are in `custom/HTI/Voice/wav_output`; CMake generates their QRC automatically.
- Custom vehicle marker is in `custom/HTI/images/aircraft_marker.png`; runtime override is custom `FlightMap/MapItems/VehicleMapItem.qml`.
- Preserve QGC Vehicle/Facts/MultiVehicleManager bindings and map coordinate/heading logic.
- The only intentional core patch is `src/Utilities/Audio/AudioOutput.*` for Vietnamese core-speech suppression.
- Use `qsTr`/`tr`, not language if/else text.
- Make null-safe active vehicle/Fact access.
- Build Debug after a material patch when possible; run `git diff --check`.
- Update both `lich_su_thay_doi.csv` files and this document when architecture/build/behavior changes materially.

## 18. Source of Truth

Priority order:

1. Current source code.
2. Current `git diff` and `git status`.
3. `custom/HTI/lich_su_thay_doi.csv` and root `lich_su_thay_doi.csv`.
4. This `AI_PROJECT_CONTEXT.md` handoff document.

If an entry conflicts with current code, **SOURCE CODE WINS**.

## 19. Validation Record

- Paths, class names and QML component names above were checked against the current source tree.
- Main Release cache, executable path, generator, compiler, Qt prefix, GStreamer path and custom directory were checked from `build/hti/CMakeCache.txt`.
- A separate HTI Debug build linked `NGroundControl.exe` after the custom marker resource was added.
- The current main Release target `build/hti` was run through CMake/Ninja on 2026-08-25 and was up to date (`ninja: no work to do`).
- Custom marker QML lint: 0 errors; remaining warnings are inherited unqualified-access patterns also present in the stock component.
- Generated resource output was checked for the custom marker QML and `aircraft_marker.png`.
- No live vehicle/map/voice hardware test was performed during this document task.

## 20. Maintenance Rule

After each large task:

1. Update `custom/HTI/lich_su_thay_doi.csv` and root `lich_su_thay_doi.csv`.
2. Update only the relevant sections of `AI_PROJECT_CONTEXT.md` when architecture, structure, build process or materially important behavior changes.
3. Preserve this document's evidence-based language; label untested work as untested.
