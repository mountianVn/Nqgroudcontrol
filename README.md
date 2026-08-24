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

<img width="1918" height="1032" alt="image" src="https://github.com/user-attachments/assets/2687ad92-7eee-4b42-b05b-21a9dad4b708" />



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
| 13 | Thông báo giọng nói WAV offline | Thêm `HTIVoiceManager` phát toàn bộ cảnh báo HTI bằng WAV đóng gói trong resource; không dùng cloud TTS. | Phát âm nhất quán, hoạt động khi không có Internet. | `custom/HTI/Voice/HTIVoiceManager.*`, `Voice/wav_output/` |
| 14 | Điều khiển giọng nói theo ngôn ngữ | WAV tiếng Việt chỉ phát với giao diện Tiếng Việt; giọng core tiếng Anh bị chặn ở chế độ này. Khi chuyển English, WAV tiếng Việt dừng và core speech được bật lại. | Không còn chồng tiếng Anh và tiếng Việt. | `CustomPlugin.*`, `AudioOutput.*`, `HTIVoiceManager.*` |
| 15 | Cảnh báo trạng thái phương tiện | Cảnh báo kết nối, ARM/DISARM, GPS, pin, mode bay, mission, PreArm và các mẫu STATUSTEXT an toàn qua mapping có kiểm soát. Có priority, cooldown và chống lặp. | Cảnh báo quan trọng rõ ràng mà không đọc tràn lan mọi MAVLink STATUSTEXT. | `HTIVoiceManager.cc`, WAV HTI |
| 16 | Thông báo pin động | Đọc phần trăm pin còn lại mỗi khi giảm ít nhất 5 điểm phần trăm so với lần thông báo trước; giữ cảnh báo pin yếu/nguy hiểm riêng. | Theo dõi pin chủ động, không spam theo từng telemetry update. | `HTIVoiceManager.cc`, `BatteryFactGroup` |
| 17 | Khoảng cách Home và tổng đường bay | Đọc độc lập `distanceToHome` và `flightDistance`: Home theo bậc 1 km hai chiều, chi tiết mỗi 100 m khi quay về dưới 1 km; tổng quãng đường đọc mỗi 3 km. | Phân biệt rõ khoảng cách quay về và quãng đường đã di chuyển. | `VehicleFactGroup`, `HTIVoiceManager.cc` |
| 18 | Độ cao và hạ cánh thấp | Đọc độ cao mỗi 100 m; khi hạ dưới 50 m đọc mỗi 10 m; từ 1-10 m đọc liên tục khi bộ phát rảnh; dưới 1 m chỉ đọc một lần và dừng tại 0 m hoặc DISARM. Độ cao dưới 1 km dùng đơn vị mét. | Hỗ trợ nhận biết chính xác giai đoạn tiếp cận, hạ cánh và chạm đất. | `HTIVoiceManager.cc`, WAV số/đơn vị |
| 19 | Phát câu động tiếng Việt/English | Ghép WAV số, phần thập phân và đơn vị để đọc pin, độ cao, khoảng cách Home và tổng quãng đường; tốc độ phát đặt `1.20x`. | Câu đọc có giá trị telemetry động mà vẫn dùng hoàn toàn WAV offline. | `HTIVoiceManager.cc`, `Voice/wav_output/` |

## Trạng Thái

- Backend MAVLink, Vehicle, LinkManager và logic telemetry không bị thay đổi.
- Catalog `.ts` đã được kiểm tra XML và placeholder động.
- Cần chạy `lrelease`/build bằng Qt Creator để tạo lại `.qm` sau các lần cập nhật catalog gần nhất.

