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
