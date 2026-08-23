import fs from "node:fs/promises";
import { Workbook } from "@oai/artifact-tool";

const outputPath =
  "C:/Users/ADMIN/Desktop/QG/qgroundcontrol/custom/HTI/Voice/DANH_SACH_AM_THANH_KHOANG_CACH_HOME_TONG_EXCEL.csv";
const rows = [
  ["NgonNgu", "Nhom", "TenFileWav", "CauDoc", "BatBuoc", "GhiChu"],
  ["Tieng Viet", "Cau mo dau", "vi_khoang_cach_den_home.wav", "Khoảng cách đến điểm Home", "Có", "Dùng trước giá trị khoảng cách từ máy bay đến Home"],
  ["Tieng Viet", "Cau mo dau", "vi_tong_quang_duong_da_bay.wav", "Tổng quãng đường đã bay", "Có", "Dùng trước giá trị flightDistance tích lũy"],
  ["English", "Opening phrase", "en_distance_to_home.wav", "Distance to Home", "Có", "Used before the aircraft-to-Home distance"],
  ["English", "Opening phrase", "en_total_distance_traveled.wav", "Total distance traveled", "Có", "Used before cumulative flight distance"],
];

const escapeCsv = (value) => `"${String(value).replaceAll('"', '""')}"`;
const csvText = `\uFEFF${rows.map((row) => row.map(escapeCsv).join(",")).join("\r\n")}\r\n`;

const workbook = await Workbook.fromCSV(csvText, { sheetName: "Khoang cach" });
const inspection = await workbook.inspect({
  kind: "table",
  range: "A1:F5",
  include: "values",
  tableMaxRows: 5,
  tableMaxCols: 6,
});

await fs.writeFile(outputPath, csvText, "utf8");
console.log(inspection.ndjson);
