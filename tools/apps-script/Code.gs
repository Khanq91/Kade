/**
 * Kade — remote config cho nghỉ bù theo năm.
 * Đọc tab "overrides" của Sheet chứa script này và trả JSON.
 *
 * Tab "overrides", dòng 1 là header, các cột:
 *   A year (số)  | B date (YYYY-MM-DD hoặc ô kiểu Date) | C kind (off|work) | D note
 *
 * Output:
 * {
 *   "version": 1726000000000,          // epoch ms lần sửa Sheet gần nhất — tự động, không cần bump tay
 *   "updatedAt": "2026-09-09T10:00:00.000Z",
 *   "years": { "2027": { "off": ["2027-02-05", ...], "work": ["2027-02-13"] } }
 * }
 */

var SHEET_NAME = 'overrides';
var CACHE_SECONDS = 300; // 5 phút, giảm cold start; sửa Sheet xong tối đa 5 phút mới thấy

function doGet(e) {
  var cache = CacheService.getScriptCache();
  var cached = cache.get('overrides');
  var body = cached || buildJson_();
  if (!cached) cache.put('overrides', body, CACHE_SECONDS);
  return ContentService.createTextOutput(body).setMimeType(ContentService.MimeType.JSON);
}

function buildJson_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) throw new Error('Không có tab ' + SHEET_NAME);

  var rows = sheet.getDataRange().getValues();
  var years = {};
  for (var i = 1; i < rows.length; i++) {
    var year = String(rows[i][0]).trim();
    var date = toIsoDate_(rows[i][1]);
    var kind = String(rows[i][2]).trim().toLowerCase();
    if (!year || !date) continue;
    if (kind !== 'off' && kind !== 'work') continue;
    if (!years[year]) years[year] = { off: [], work: [] };
    years[year][kind].push(date);
  }
  Object.keys(years).forEach(function (y) {
    years[y].off.sort();
    years[y].work.sort();
  });

  var lastUpdated = DriveApp.getFileById(ss.getId()).getLastUpdated();
  return JSON.stringify({
    version: lastUpdated.getTime(),
    updatedAt: lastUpdated.toISOString(),
    years: years
  });
}

function toIsoDate_(v) {
  if (v instanceof Date) {
    // Ô kiểu Date: lấy theo múi giờ của Sheet, tránh lệch ngày
    return Utilities.formatDate(v, SpreadsheetApp.getActiveSpreadsheet().getSpreadsheetTimeZone(), 'yyyy-MM-dd');
  }
  var s = String(v).trim();
  return /^\d{4}-\d{2}-\d{2}$/.test(s) ? s : '';
}

/** Chạy tay trong editor để xem output trước khi deploy. (Không đặt tên kết thúc bằng _ — Apps Script ẩn hàm đó khỏi dropdown Chạy.) */
function testConfig() {
  Logger.log(buildJson_());
}
