// Kade lunar engine (port of docs/reference/amlich-aa98.js + lunar_core + calendar_data).
const PI = Math.PI, TZ = 7;
const INT = Math.floor;
export function jdFromDate(dd, mm, yy) {
  const a = INT((14 - mm) / 12), y = yy + 4800 - a, m = mm + 12 * a - 3;
  let jd = dd + INT((153 * m + 2) / 5) + 365 * y + INT(y / 4) - INT(y / 100) + INT(y / 400) - 32045;
  if (jd < 2299161) jd = dd + INT((153 * m + 2) / 5) + 365 * y + INT(y / 4) - 32083;
  return jd;
}
export function jdToDate(jd) {
  let a, b, c;
  if (jd > 2299160) { a = jd + 32044; b = INT((4 * a + 3) / 146097); c = a - INT((b * 146097) / 4); }
  else { b = 0; c = jd + 32082; }
  const d = INT((4 * c + 3) / 1461), e = c - INT((1461 * d) / 4), m = INT((5 * e + 2) / 153);
  return [e - INT((153 * m + 2) / 5) + 1, m + 3 - 12 * INT(m / 10), b * 100 + d - 4800 + INT(m / 10)];
}
function NewMoon(k) {
  const T = k / 1236.85, T2 = T * T, T3 = T2 * T, dr = PI / 180;
  let Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
  Jd1 += 0.00033 * Math.sin((166.56 + 132.87 * T - 0.009173 * T2) * dr);
  const M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
  const Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
  const F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3;
  let C1 = (0.1734 - 0.000393 * T) * Math.sin(M * dr) + 0.0021 * Math.sin(2 * dr * M);
  C1 = C1 - 0.4068 * Math.sin(Mpr * dr) + 0.0161 * Math.sin(dr * 2 * Mpr);
  C1 = C1 - 0.0004 * Math.sin(dr * 3 * Mpr);
  C1 = C1 + 0.0104 * Math.sin(dr * 2 * F) - 0.0051 * Math.sin(dr * (M + Mpr));
  C1 = C1 - 0.0074 * Math.sin(dr * (M - Mpr)) + 0.0004 * Math.sin(dr * (2 * F + M));
  C1 = C1 - 0.0004 * Math.sin(dr * (2 * F - M)) - 0.0006 * Math.sin(dr * (2 * F + Mpr));
  C1 = C1 + 0.0010 * Math.sin(dr * (2 * F - Mpr)) + 0.0005 * Math.sin(dr * (2 * Mpr + M));
  const deltat = T < -11 ? 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3 : -0.000278 + 0.000265 * T + 0.000262 * T2;
  return Jd1 + C1 - deltat;
}
function SunLongitude(jdn) {
  const T = (jdn - 2451545.0) / 36525, T2 = T * T, dr = PI / 180;
  const M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2;
  const L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2;
  let DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * Math.sin(dr * M);
  DL += (0.019993 - 0.000101 * T) * Math.sin(dr * 2 * M) + 0.000290 * Math.sin(dr * 3 * M);
  let L = (L0 + DL) * dr;
  return L - PI * 2 * INT(L / (PI * 2));
}
const getSunLongitude = (dn, tz) => INT(SunLongitude(dn - 0.5 - tz / 24) / PI * 6);
const getNewMoonDay = (k, tz) => INT(NewMoon(k) + 0.5 + tz / 24);
function getLunarMonth11(yy, tz) {
  const off = jdFromDate(31, 12, yy) - 2415021, k = INT(off / 29.530588853);
  let nm = getNewMoonDay(k, tz);
  if (getSunLongitude(nm, tz) >= 9) nm = getNewMoonDay(k - 1, tz);
  return nm;
}
function getLeapMonthOffset(a11, tz) {
  const k = INT((a11 - 2415021.076998695) / 29.530588853 + 0.5);
  let last = 0, i = 1, arc = getSunLongitude(getNewMoonDay(k + i, tz), tz);
  do { last = arc; i++; arc = getSunLongitude(getNewMoonDay(k + i, tz), tz); } while (arc != last && i < 14);
  return i - 1;
}
export function solarToLunar(dd, mm, yy, tz = TZ) {
  const dayNumber = jdFromDate(dd, mm, yy), k = INT((dayNumber - 2415021.076998695) / 29.530588853);
  let monthStart = getNewMoonDay(k + 1, tz);
  if (monthStart > dayNumber) monthStart = getNewMoonDay(k, tz);
  if (monthStart > dayNumber) monthStart = getNewMoonDay(k - 1, tz);
  let a11 = getLunarMonth11(yy, tz), b11 = a11, lunarYear;
  if (a11 >= monthStart) { lunarYear = yy; a11 = getLunarMonth11(yy - 1, tz); }
  else { lunarYear = yy + 1; b11 = getLunarMonth11(yy + 1, tz); }
  const lunarDay = dayNumber - monthStart + 1, diff = INT((monthStart - a11) / 29);
  let lunarLeap = 0, lunarMonth = diff + 11;
  if (b11 - a11 > 365) {
    const leapMonthDiff = getLeapMonthOffset(a11, tz);
    if (diff >= leapMonthDiff) { lunarMonth = diff + 10; if (diff == leapMonthDiff) lunarLeap = 1; }
  }
  if (lunarMonth > 12) lunarMonth -= 12;
  if (lunarMonth >= 11 && diff < 4) lunarYear -= 1;
  return { day: lunarDay, month: lunarMonth, year: lunarYear, isLeap: lunarLeap === 1 };
}
export function lunarToSolar(lunarDay, lunarMonth, lunarYear, lunarLeap, tz = TZ) {
  let a11, b11;
  if (lunarMonth < 11) { a11 = getLunarMonth11(lunarYear - 1, tz); b11 = getLunarMonth11(lunarYear, tz); }
  else { a11 = getLunarMonth11(lunarYear, tz); b11 = getLunarMonth11(lunarYear + 1, tz); }
  const k = INT(0.5 + (a11 - 2415021.076998695) / 29.530588853);
  let off = lunarMonth - 11; if (off < 0) off += 12;
  if (b11 - a11 > 365) {
    const leapOff = getLeapMonthOffset(a11, tz);
    let leapMonth = leapOff - 2; if (leapMonth < 0) leapMonth += 12;
    if (lunarLeap && lunarMonth != leapMonth) return null;
    else if (lunarLeap || off >= leapOff) off += 1;
  }
  const [d, m, y] = jdToDate(getNewMoonDay(k + off, tz) + lunarDay - 1);
  if (d === 0) return null;
  const check = solarToLunar(d, m, y, tz);
  if (check.day !== lunarDay || check.month !== lunarMonth) return null;
  return new Date(Date.UTC(y, m - 1, d));
}
// ── Can chi, hoàng đạo, tiết khí ──
export const CAN = ['Giáp','Ất','Bính','Đinh','Mậu','Kỷ','Canh','Tân','Nhâm','Quý'];
export const CHI = ['Tý','Sửu','Dần','Mão','Thìn','Tỵ','Ngọ','Mùi','Thân','Dậu','Tuất','Hợi'];
export const canChiYear = y => `${CAN[(y + 6) % 10]} ${CHI[(y + 8) % 12]}`;
const chiIndexOfMonth = m => (m + 1) % 12;
const canChiMonth = (m, y) => `${CAN[(y * 12 + m + 3) % 10]} ${CHI[chiIndexOfMonth(m)]}`;
const chiIndexOfDay = jd => (jd + 1) % 12;
const canChiDay = jd => `${CAN[(jd + 9) % 10]} ${CHI[chiIndexOfDay(jd)]}`;
const THAN = ['Thanh Long','Minh Đường','Thiên Hình','Chu Tước','Kim Quỹ','Kim Đường','Bạch Hổ','Ngọc Đường','Thiên Lao','Nguyên Vũ','Tư Mệnh','Câu Trận'];
const HD = ['110100101100','001101001011','110011010010','101100110100','001011001101','010010110011','110100101100','001101001011','110011010010','101100110100','001011001101','010010110011'];
const gioHoangDao = dc => { const r = HD[dc], out = []; for (let i = 0; i < 12; i++) if (r[i] === '1') out.push(`${CHI[i]} (${(i * 2 + 23) % 24}-${(i * 2 + 1) % 24})`); return out; };
const isNgayHoangDao = (mc, dc) => HD[mc][dc] === '1';
const thanOfDay = (mc, dc) => THAN[(((dc - ((2 * mc - 4) % 12)) % 12) + 12) % 12];
const TIET = ['Xuân phân','Thanh minh','Cốc vũ','Lập hạ','Tiểu mãn','Mang chủng','Hạ chí','Tiểu thử','Đại thử','Lập thu','Xử thử','Bạch lộ','Thu phân','Hàn lộ','Sương giáng','Lập đông','Tiểu tuyết','Đại tuyết','Đông chí','Tiểu hàn','Đại hàn','Lập xuân','Vũ thủy','Kinh trập'];
const tkIdx = jd => INT(SunLongitude(jd - 0.5 - TZ / 24) / PI * 12);
const tietKhiOf = jd => { const b = tkIdx(jd), a = tkIdx(jd + 1); return b === a ? null : TIET[a]; };
// ── Strings ──
export const S = {
  weekdaysShort: ['T2','T3','T4','T5','T6','T7','CN'],
  weekdays: ['Thứ Hai','Thứ Ba','Thứ Tư','Thứ Năm','Thứ Sáu','Thứ Bảy','Chủ nhật'],
  lunarMonthNames: ['Giêng','Hai','Ba','Tư','Năm','Sáu','Bảy','Tám','Chín','Mười','Mười một','Chạp'],
  kind: { vnHoliday: 'Nghỉ lễ', vnMemorial: 'Kỷ niệm', international: 'Quốc tế', personal: 'Cá nhân' },
};
export const KIND_COLOR = { vnHoliday: '#C62828', vnMemorial: '#EF6C00', international: '#1565C0' };
export const USER_COLORS = ['#6A1B9A','#00838F','#2E7D32','#AD1457','#4527A0','#00695C','#9E9D24','#5D4037'];
// ── App events (calendar_data/events.dart) ──
const E = (id, title, kind, type, month, day, extra = {}) => ({ id, title, kind, type, month, day, durationDays: 1, offsetDays: 0, ...extra });
export const EVENTS = [
  E('tet-duong-lich','Tết Dương lịch','vnHoliday','solar',1,1,{description:'Năm mới'}),
  E('giao-thua','Giao thừa','vnHoliday','lunar',1,1,{offsetDays:-1,description:'Ngày cuối năm âm (29 hoặc 30 tháng Chạp), trước mùng 1 Tết'}),
  E('tet','Tết Nguyên đán','vnHoliday','lunar',1,1,{durationDays:3,description:'Mùng 1–3; nghỉ thêm (mùng 4–5, trước Giao thừa) theo lịch từng năm'}),
  E('gio-to','Giỗ Tổ Hùng Vương','vnHoliday','lunar',3,10),
  E('giai-phong','Ngày Giải phóng miền Nam','vnHoliday','solar',4,30),
  E('quoc-te-lao-dong','Ngày Quốc tế Lao động','vnHoliday','solar',5,1),
  E('quoc-khanh','Ngày Quốc khánh','vnHoliday','solar',9,2,{description:'Ngày nghỉ thứ 2 (1/9 hoặc 3/9) theo lịch nghỉ từng năm'}),
  E('thanh-lap-dang','Ngày thành lập Đảng Cộng sản Việt Nam','vnMemorial','solar',2,3),
  E('thay-thuoc','Ngày Thầy thuốc Việt Nam','vnMemorial','solar',2,27),
  E('quoc-te-phu-nu','Ngày Quốc tế Phụ nữ','vnMemorial','solar',3,8),
  E('thanh-lap-doan','Ngày thành lập Đoàn TNCS Hồ Chí Minh','vnMemorial','solar',3,26),
  E('dien-bien-phu','Chiến thắng Điện Biên Phủ','vnMemorial','solar',5,7),
  E('sinh-nhat-bac','Ngày sinh Chủ tịch Hồ Chí Minh','vnMemorial','solar',5,19),
  E('bao-chi','Ngày Báo chí Cách mạng Việt Nam','vnMemorial','solar',6,21),
  E('gia-dinh','Ngày Gia đình Việt Nam','vnMemorial','solar',6,28),
  E('thuong-binh-liet-si','Ngày Thương binh Liệt sĩ','vnMemorial','solar',7,27),
  E('cach-mang-thang-tam','Ngày Cách mạng tháng Tám thành công','vnMemorial','solar',8,19),
  E('giai-phong-thu-do','Ngày Giải phóng Thủ đô','vnMemorial','solar',10,10),
  E('doanh-nhan','Ngày Doanh nhân Việt Nam','vnMemorial','solar',10,13),
  E('phu-nu-viet-nam','Ngày Phụ nữ Việt Nam','vnMemorial','solar',10,20),
  E('nha-giao','Ngày Nhà giáo Việt Nam','vnMemorial','solar',11,20),
  E('quan-doi','Ngày thành lập Quân đội nhân dân Việt Nam','vnMemorial','solar',12,22),
  E('ram-thang-gieng','Rằm tháng Giêng (Tết Nguyên tiêu)','vnMemorial','lunar',1,15),
  E('han-thuc','Tết Hàn thực','vnMemorial','lunar',3,3),
  E('phat-dan','Lễ Phật Đản','vnMemorial','lunar',4,15),
  E('doan-ngo','Tết Đoan Ngọ','vnMemorial','lunar',5,5),
  E('vu-lan','Lễ Vu Lan (Rằm tháng Bảy)','vnMemorial','lunar',7,15),
  E('trung-thu','Tết Trung Thu','vnMemorial','lunar',8,15),
  E('ong-tao','Ông Công Ông Táo','vnMemorial','lunar',12,23),
  E('valentine','Lễ tình nhân (Valentine)','international','solar',2,14),
  E('ca-thang-tu','Ngày Cá tháng Tư','international','solar',4,1),
  E('trai-dat','Ngày Trái Đất','international','solar',4,22),
  E('ngay-cua-me','Ngày của Mẹ','international','solar',5,0,{nth:{weekday:7,n:2},description:'Chủ nhật thứ 2 của tháng 5'}),
  E('quoc-te-thieu-nhi','Ngày Quốc tế Thiếu nhi','international','solar',6,1),
  E('ngay-cua-cha','Ngày của Cha','international','solar',6,0,{nth:{weekday:7,n:3},description:'Chủ nhật thứ 3 của tháng 6'}),
  E('nha-giao-quoc-te','Ngày Nhà giáo Quốc tế','international','solar',10,5),
  E('halloween','Halloween','international','solar',10,31),
  E('giang-sinh','Lễ Giáng sinh','international','solar',12,25),
];
// Sample personal events for the prototype.
export const USER_EVENTS = [
  { id: 'u1', title: 'Giỗ ông nội', type: 'lunar', day: 12, month: 8, year: null, durationDays: 1, colorIndex: 0, note: 'Về quê từ sáng', remind: 3 },
  { id: 'u2', title: 'Sinh nhật mẹ', type: 'solar', day: 24, month: 9, year: null, durationDays: 1, colorIndex: 3, note: null, remind: 1 },
  { id: 'u3', title: 'Kỷ niệm ngày cưới', type: 'solar', day: 18, month: 10, year: null, durationDays: 1, colorIndex: 1, note: null, remind: 7 },
  { id: 'u4', title: 'Cúng rằm', type: 'lunar', day: 15, month: 9, year: null, durationDays: 1, colorIndex: 2, note: null, remind: null },
];
// Year overrides (Sheet) — sample for 2026.
export const OVERRIDES = { 2026: { off: ['2026-01-02','2026-02-16','2026-02-20','2026-02-21','2026-09-01'], work: [] } };
const utc = (y, m, d) => new Date(Date.UTC(y, m - 1, d));
const iso = d => d.toISOString().slice(0, 10);
const addDays = (d, n) => new Date(d.getTime() + n * 86400000);
export const weekdayIdx = d => (d.getUTCDay() + 6) % 7; // 0 = T2
export const fmtDate = d => `${String(d.getUTCDate()).padStart(2,'0')}/${String(d.getUTCMonth()+1).padStart(2,'0')}/${d.getUTCFullYear()}`;
export const fmtLunarShort = l => `${l.day}/${l.month}${l.isLeap ? ' nhuận' : ''}`;
export const lunarMonthTitle = (l) => `Tháng ${S.lunarMonthNames[l.month - 1]}${l.isLeap ? ' nhuận' : ''} ${canChiYear(l.year)}`;
export function dayInfo(d) {
  const y = d.getUTCFullYear(), m = d.getUTCMonth() + 1, dd = d.getUTCDate();
  const jd = jdFromDate(dd, m, y), lunar = solarToLunar(dd, m, y), dc = chiIndexOfDay(jd), mc = chiIndexOfMonth(lunar.month);
  return { solar: d, lunar, canChiYear: canChiYear(lunar.year), canChiMonth: canChiMonth(lunar.month, lunar.year), canChiDay: canChiDay(jd), tietKhi: tietKhiOf(jd), gioHoangDao: gioHoangDao(dc), isHoangDao: isNgayHoangDao(mc, dc), than: thanOfDay(mc, dc) };
}
// Events occurring on a solar date (D020/D021 semantics, simplified).
function eventStarts(e, d) {
  const y = d.getUTCFullYear();
  if (e.type === 'solar') {
    let start;
    if (e.nth) { const first = utc(y, e.month, 1); const day = 1 + (e.nth.weekday - (first.getUTCDay() || 7) + 7) % 7 + 7 * (e.nth.n - 1); start = utc(y, e.month, day); if (start.getUTCMonth() + 1 !== e.month) return null; }
    else start = utc(y, e.month, e.day);
    return addDays(start, e.offsetDays);
  }
  // lunar: try lunar years y-1..y+1
  for (const ly of [y - 1, y, y + 1]) { const s = lunarToSolar(e.day, e.month, ly, false); if (s) { const st = addDays(s, e.offsetDays); if (d >= st && d < addDays(st, e.durationDays)) return st; } }
  return null;
}
export function appEventsOn(d) {
  return EVENTS.filter(e => { const st = eventStarts(e, d); return st && d >= st && d < addDays(st, e.durationDays); });
}
export function userEventsOn(d, list = USER_EVENTS) {
  const y = d.getUTCFullYear();
  return list.filter(e => {
    if (e.year && e.year !== y) return false;
    if (e.type === 'solar') return d.getUTCMonth() + 1 === e.month && d.getUTCDate() === e.day;
    const l = solarToLunar(d.getUTCDate(), d.getUTCMonth() + 1, y);
    return l.day === e.day && l.month === e.month && !l.isLeap;
  });
}
export function dayCell(d, userEvents = USER_EVENTS) {
  const info = dayInfo(d), app = appEventsOn(d), user = userEventsOn(d, userEvents);
  const ov = OVERRIDES[d.getUTCFullYear()], k = iso(d);
  const isOff = (app.some(e => e.kind === 'vnHoliday') || (ov && ov.off.includes(k))) && !(ov && ov.work.includes(k));
  return { date: d, info, appEvents: app, userEvents: user, isOffDay: isOff };
}
export function buildMonth(y, m, userEvents = USER_EVENTS) {
  const n = new Date(Date.UTC(y, m, 0)).getUTCDate(), days = [];
  for (let d = 1; d <= n; d++) days.push(dayCell(utc(y, m, d), userEvents));
  return { year: y, month: m, days };
}
export function upcoming(today, windowDays = 60, layers = new Set(['vnHoliday','vnMemorial','international','personal']), userEvents = USER_EVENTS) {
  const out = [];
  for (let i = 0; i < windowDays; i++) {
    const d = addDays(today, i), c = dayCell(d, userEvents), prev = dayCell(addDays(d, -1), userEvents);
    const items = [];
    for (const e of c.appEvents) if (layers.has(e.kind) && (i === 0 || !prev.appEvents.includes(e))) items.push({ title: e.title, type: e.type, layer: e.kind, color: KIND_COLOR[e.kind], durationDays: e.durationDays, date: d });
    if (layers.has('personal')) for (const e of c.userEvents) if (i === 0 || !prev.userEvents.some(x => x.id === e.id)) items.push({ title: e.title, type: e.type, layer: 'personal', color: USER_COLORS[e.colorIndex % 8], durationDays: e.durationDays, date: d, user: e });
    if (items.length) out.push({ cell: c, daysFromToday: i, items });
  }
  return out;
}
export { utc, iso, addDays };
