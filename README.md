<p align="center">
  <img src="https://raw.githubusercontent.com/Dronecode/UX-Design/35d8148a8a0559cd4bcf50bfa2c94614983cce91/QGC/Branding/Deliverables/QGC_RGB_Logo_Horizontal_Positive_PREFERRED/QGC_RGB_Logo_Horizontal_Positive_PREFERRED.svg" alt="QGroundControl Logo" width="500">
</p>

<p align="center">
  <a href="https://github.com/mavlink/QGroundControl/releases"><img src="https://img.shields.io/github/v/release/mavlink/QGroundControl" alt="Latest Release"></a>
  <a href="https://github.com/mavlink/qgroundcontrol/blob/master/.github/COPYING.md"><img src="https://img.shields.io/github/license/mavlink/QGroundControl" alt="License"></a>
  <a href="https://github.com/mavlink/QGroundControl/actions/workflows/linux.yml"><img src="https://github.com/mavlink/QGroundControl/actions/workflows/linux.yml/badge.svg" alt="Linux Build"></a>
  <a href="https://securityscorecards.dev/viewer/?uri=github.com/mavlink/qgroundcontrol"><img src="https://img.shields.io/ossf-scorecard/github.com/mavlink/qgroundcontrol?label=openssf%20scorecard" alt="OpenSSF Scorecard"></a>
  <a href="https://crowdin.com/project/qgroundcontrol"><img src="https://badges.crowdin.net/qgroundcontrol/localized.svg" alt="Crowdin"></a>
  <a href="https://discord.com/channels/1022170275984457759/1022185820683255908"><img src="https://img.shields.io/discord/1022170275984457759?logo=discord&logoColor=white&label=Discord" alt="Dronecode Discord"></a>
  <a href="https://doi.org/10.5281/zenodo.595404"><img src="https://zenodo.org/badge/DOI/10.5281/zenodo.595404.svg" alt="DOI"></a>
</p>

**QGroundControl** (QGC) is a Ground Control Station (GCS) for UAVs, providing full flight control
and mission planning for any *MAVLink-enabled* drone, including *PX4* and *ArduPilot* platforms.

## Features

- **Mission planning** — plan, edit, and fly autonomous waypoint, survey, and structure-scan missions.
- **Live Fly View** — real-time flight display with map, instruments, and full vehicle telemetry.
- **Vehicle setup** — guided wizards for sensor calibration, radio, flight modes, and power.
- **Parameter tuning** — inspect and edit every vehicle parameter through the Fact System.
- **Video streaming** — GStreamer-based UDP RTP / RTSP video with recording in the Flight Display.
- **Multi-vehicle** — connect to and monitor multiple vehicles simultaneously.
- **MAVLink tooling** — built-in MAVLink Inspector, console, and log download/analysis.
- **Cross-platform** — Windows, macOS, Linux, Android, and iOS from a single codebase.

## Download

Grab the latest stable build for your platform, or see all assets on the
[releases page](https://github.com/mavlink/QGroundControl/releases/latest):

<p align="center">
  <a href="https://github.com/mavlink/QGroundControl/releases/latest/download/QGroundControl-installer.exe"><img src="https://img.shields.io/badge/Windows-0078D6?logo=windows&logoColor=white" alt="Windows"></a>
  <a href="https://github.com/mavlink/QGroundControl/releases/latest/download/QGroundControl.dmg"><img src="https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white" alt="macOS"></a>
  <a href="https://github.com/mavlink/QGroundControl/releases/latest/download/QGroundControl-x86_64.AppImage"><img src="https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black" alt="Linux (AppImage)"></a>
  <a href="https://github.com/mavlink/QGroundControl/releases/latest/download/QGroundControl.apk"><img src="https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white" alt="Android"></a>
</p>

## Links

- [Official Website](http://qgroundcontrol.com)
- [User Manual](https://docs.qgroundcontrol.com/en/)
- [Developer Guide](https://dev.qgroundcontrol.com/en/) / [Build Instructions](https://dev.qgroundcontrol.com/en/getting_started/)
- [Discussion & Support](https://docs.qgroundcontrol.com/en/Support/Support.html)
- [Dronecode Discord](https://discord.com/channels/1022170275984457759/1022185820683255908)
- [Security Policy](.github/SECURITY.md)
- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [License](https://github.com/mavlink/qgroundcontrol/blob/master/.github/COPYING.md)

## Contributing

QGC is open source and welcomes contributions. See [AGENTS.md](AGENTS.md) for build/test/lint
commands and coding conventions, and [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md) for
architecture patterns and the contribution workflow.

QGC's interface is translated by the community — help translate it into your language on
[Crowdin](https://crowdin.com/project/qgroundcontrol).

## Star history

[![Star History Chart](https://api.star-history.com/svg?repos=mavlink/qgroundcontrol&type=Date)](https://star-history.com/#mavlink/qgroundcontrol&Date)
# Bảng Mô Tả Chức Năng Cải Tiến

| STT | Chức năng | Mô tả cải tiến | Giá trị sử dụng | Thành phần chính |
|---:|---|---|---|---|
| 1 | Giao diện HTI | Thiết kế lại bảng điều khiển bên phải theo phong cách dark glass, có tab `Chức năng` và `Nhiệm vụ`, nút trạng thái, ô nhập và màu cảnh báo rõ ràng. | Dễ quan sát và thao tác trong khi bay. | `custom/HTI/qml/HTIRightControlPanel.qml`, `HTIModernButton.qml`, `HTIPanelTabButton.qml` |
| 2 | Điều khiển bay nhanh | Bổ sung thao tác `Auto`, `Loiter`, `QLoiter`, đặt WP, đặt bán kính, đặt độ cao, `Quay về Home` và `Hạ cánh khẩn cấp`. | Giảm số bước khi điều khiển phương tiện. | `custom/HTI/qml/HTIFunctionsPanel.qml` |
| 3 | Kiểm tra trước chuyến bay | Hiển thị trạng thái sẵn sàng bay, tình trạng cảm biến và cảnh báo PreArm. | Phát hiện điều kiện chưa an toàn trước khi cất cánh. | `HTIFunctionsPanel.qml`, `Vehicle` properties |
| 4 | Hiển thị telemetry | Hiển thị số vệ tinh GPS, vĩ độ, kinh độ, tốc độ khí, tốc độ mặt đất, tốc độ gió, tín hiệu, pin, điện áp, dòng điện và thời gian ước tính. | Theo dõi nhanh các thông số quan trọng. | `HTIFunctionsPanel.qml`, `HTIStatusRow.qml` |
| 5 | Lịch sử log MAVLink | FunctionPanel giữ lịch sử riêng từ `newFormattedMessage`, đồng bộ snapshot ban đầu và không mất log khi bảng Vehicle Messages chuẩn reset dữ liệu dùng chung. | Log hiển thị đầy đủ và ổn định hơn. | `HTIFunctionsPanel.qml` |
| 6 | Dịch log firmware | Nhận diện và dịch các mẫu `PreArm`, `EKF`, `AHRS`, `RCOut`, `IMU`, `Barometer`, `ArduPilot Ready`; vẫn giữ số cảm biến, PWM và giá trị động. | Người vận hành hiểu cảnh báo từ PX4/ArduPilot nhanh hơn. | `HTIFunctionsPanel.qml`, `qgc_source_vi_VN.ts` |
| 7 | Hỗ trợ tiếng Việt | Thêm `Tiếng Việt` vào bộ chọn ngôn ngữ QGC theo cơ chế Qt Translation chuẩn. | Có thể chuyển giữa English và Tiếng Việt theo cấu hình QGC. | `src/Settings/AppSettings.cc`, `qgc_source_vi_VN.ts`, `qgc_json_vi_VN.ts` |
| 8 | Dịch giao diện QGC | Dịch catalog source và JSON cho giao diện, cài đặt, Plan View, dialog và nội dung nhiệm vụ. | Giao diện thống nhất tiếng Việt, không hard-code theo if/else. | `translations/qgc_source_vi_VN.ts`, `translations/qgc_json_vi_VN.ts` |
| 9 | Chuẩn hóa thuật ngữ UAV | Chuẩn hóa `ARM` thành `Khởi động máy bay`, `Disarm` thành `Tắt máy`, `Takeoff` thành `Cất cánh`, `Land` thành `Hạ cánh`, `Vehicle` thành `Phương tiện`; giữ nguyên `MAVLink`, `PX4`, `ArduPilot`, `Auto`, `Guided`, `Loiter`, `RTL`, `WP`. | Tránh các bản dịch máy sai ngữ cảnh hàng không không người lái. | Hai catalog tiếng Việt |
| 10 | Thiết lập nhiệm vụ | Dịch Plan Info, Defaults, Plan Templates, Survey, Corridor Scan, Structure Scan, Alt Frame, độ cao waypoint và nhóm tốc độ. | Tạo và chỉnh sửa nhiệm vụ dễ hiểu hơn. | `src/PlanView/PlanInfoEditor.qml`, `MissionDefaultsEditor.qml`, catalog JSON/source |
| 11 | Nhãn camera | Đưa `Landscape` và `Portrait` vào `qsTr` để có thể dịch theo ngôn ngữ. | Không còn text giao diện bị bỏ sót trong thiết lập camera. | `src/PlanView/CameraCalcCamera.qml` |
| 12 | Lịch sử thay đổi | Ghi nhận các lần cải tiến vào CSV lịch sử của HTI và dự án. | Dễ truy vết thay đổi và nghiệm thu. | `custom/HTI/lich_su_thay_doi.csv`, `lich_su_thay_doi.csv` |

## Trạng Thái

- Backend MAVLink, Vehicle, LinkManager và logic telemetry không bị thay đổi.
- Catalog `.ts` đã được kiểm tra XML và placeholder động.
- Cần chạy `lrelease`/build bằng Qt Creator để tạo lại `.qm` sau các lần cập nhật catalog gần nhất.
