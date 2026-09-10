// Port 1:1 của docs/reference/amlich-aa98.js — Hồ Ngọc Đức (2006), thuật toán
// từ Jean Meeus, "Astronomical Algorithms" (1998).
//
// Giữ NGUYÊN tên hàm, thứ tự tham số và cấu trúc từng dòng của bản JS để đối
// chiếu từng hàm khi test. Vì vậy tắt lint đặt tên cho file này.
// Mảng JS được thay bằng record cùng thứ tự phần tử; INT = Math.floor.
//
// License gốc: "personal, non-commercial use" — xem .memory/DECISIONS.md D009.
//
// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

/// Bỏ phần lẻ (làm tròn xuống), ví dụ INT(3.2) = 3; JS: `Math.floor`.
int INT(num d) => d.floor();

/// Số ngày Julius (nguyên) của ngày dd/mm/yyyy, tính từ 1/1/4713 TCN (lịch Julius).
int jdFromDate(int dd, int mm, int yy) {
  final a = INT((14 - mm) / 12);
  final y = yy + 4800 - a;
  final m = mm + 12 * a - 3;
  var jd =
      dd +
      INT((153 * m + 2) / 5) +
      365 * y +
      INT(y / 4) -
      INT(y / 100) +
      INT(y / 400) -
      32045;
  if (jd < 2299161) {
    jd = dd + INT((153 * m + 2) / 5) + 365 * y + INT(y / 4) - 32083;
  }
  return jd;
}

/// Đổi số ngày Julius (nguyên) sang (ngày, tháng, năm) dương lịch.
(int day, int month, int year) jdToDate(int jd) {
  int a, b, c;
  if (jd > 2299160) {
    // After 5/10/1582, Gregorian calendar
    a = jd + 32044;
    b = INT((4 * a + 3) / 146097);
    c = a - INT((b * 146097) / 4);
  } else {
    b = 0;
    c = jd + 32082;
  }
  final d = INT((4 * c + 3) / 1461);
  final e = c - INT((1461 * d) / 4);
  final m = INT((5 * e + 2) / 153);
  final day = e - INT((153 * m + 2) / 5) + 1;
  final month = m + 3 - 12 * INT(m / 10);
  final year = b * 100 + d - 4800 + INT(m / 10);
  return (day, month, year);
}

/// Thời điểm sóc thứ k tính từ sóc 1/1/1900 13:52 UTC, đơn vị ngày Julius (số thực).
double NewMoon(int k) {
  final T = k / 1236.85; // Time in Julian centuries from 1900 January 0.5
  final T2 = T * T;
  final T3 = T2 * T;
  final dr = math.pi / 180;
  var Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
  Jd1 =
      Jd1 +
      0.00033 *
          math.sin((166.56 + 132.87 * T - 0.009173 * T2) * dr); // Mean new moon
  final M =
      359.2242 +
      29.10535608 * k -
      0.0000333 * T2 -
      0.00000347 * T3; // Sun's mean anomaly
  final Mpr =
      306.0253 +
      385.81691806 * k +
      0.0107306 * T2 +
      0.00001236 * T3; // Moon's mean anomaly
  final F =
      21.2964 +
      390.67050646 * k -
      0.0016528 * T2 -
      0.00000239 * T3; // Moon's argument of latitude
  var C1 =
      (0.1734 - 0.000393 * T) * math.sin(M * dr) +
      0.0021 * math.sin(2 * dr * M);
  C1 = C1 - 0.4068 * math.sin(Mpr * dr) + 0.0161 * math.sin(dr * 2 * Mpr);
  C1 = C1 - 0.0004 * math.sin(dr * 3 * Mpr);
  C1 = C1 + 0.0104 * math.sin(dr * 2 * F) - 0.0051 * math.sin(dr * (M + Mpr));
  C1 =
      C1 -
      0.0074 * math.sin(dr * (M - Mpr)) +
      0.0004 * math.sin(dr * (2 * F + M));
  C1 =
      C1 -
      0.0004 * math.sin(dr * (2 * F - M)) -
      0.0006 * math.sin(dr * (2 * F + Mpr));
  C1 =
      C1 +
      0.0010 * math.sin(dr * (2 * F - Mpr)) +
      0.0005 * math.sin(dr * (2 * Mpr + M));
  double deltat;
  if (T < -11) {
    deltat =
        0.001 +
        0.000839 * T +
        0.0002261 * T2 -
        0.00000845 * T3 -
        0.000000081 * T * T3;
  } else {
    deltat = -0.000278 + 0.000265 * T + 0.000262 * T2;
  }
  final JdNew = Jd1 + C1 - deltat;
  return JdNew;
}

/// Kinh độ Mặt Trời (radian, chuẩn hóa về [0, 2π)) tại thời điểm jdn (ngày Julius, số thực).
double SunLongitude(double jdn) {
  final T =
      (jdn - 2451545.0) /
      36525; // Time in Julian centuries from 2000-01-01 12:00:00 GMT
  final T2 = T * T;
  final dr = math.pi / 180; // degree to radian
  final M =
      357.52910 +
      35999.05030 * T -
      0.0001559 * T2 -
      0.00000048 * T * T2; // mean anomaly, degree
  final L0 =
      280.46645 + 36000.76983 * T + 0.0003032 * T2; // mean longitude, degree
  var DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * math.sin(dr * M);
  DL =
      DL +
      (0.019993 - 0.000101 * T) * math.sin(dr * 2 * M) +
      0.000290 * math.sin(dr * 3 * M);
  var L = L0 + DL; // true longitude, degree
  L = L * dr;
  L = L - math.pi * 2 * (INT(L / (math.pi * 2))); // Normalize to (0, 2*PI)
  return L;
}

/// Chỉ số cung 30° của Mặt Trời (0..11) lúc 0h địa phương của ngày dayNumber, múi giờ timeZone.
int getSunLongitude(int dayNumber, double timeZone) {
  return INT(SunLongitude(dayNumber - 0.5 - timeZone / 24) / math.pi * 6);
}

/// Ngày Julius (nguyên, theo lịch địa phương múi giờ timeZone) chứa sóc thứ k.
int getNewMoonDay(int k, double timeZone) {
  return INT(NewMoon(k) + 0.5 + timeZone / 24);
}

/// Ngày Julius bắt đầu tháng 11 âm lịch (tháng chứa Đông chí) của năm dương yy.
int getLunarMonth11(int yy, double timeZone) {
  // off = jdFromDate(31, 12, yy) - 2415021.076998695;
  final off = jdFromDate(31, 12, yy) - 2415021;
  final k = INT(off / 29.530588853);
  var nm = getNewMoonDay(k, timeZone);
  final sunLong = getSunLongitude(
    nm,
    timeZone,
  ); // sun longitude at local midnight
  if (sunLong >= 9) {
    nm = getNewMoonDay(k - 1, timeZone);
  }
  return nm;
}

/// Vị trí (tính từ tháng sau tháng 11 bắt đầu ngày a11) của tháng nhuận.
int getLeapMonthOffset(int a11, double timeZone) {
  final k = INT((a11 - 2415021.076998695) / 29.530588853 + 0.5);
  var last = 0;
  var i = 1; // We start with the month following lunar month 11
  var arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
  do {
    last = arc;
    i++;
    arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
  } while (arc != last && i < 14);
  return i - 1;
}

/// Đổi ngày dương dd/mm/yyyy sang âm lịch: (ngày, tháng, năm, nhuận 0/1).
(int day, int month, int year, int leap) convertSolar2Lunar(
  int dd,
  int mm,
  int yy,
  double timeZone,
) {
  final dayNumber = jdFromDate(dd, mm, yy);
  final k = INT((dayNumber - 2415021.076998695) / 29.530588853);
  var monthStart = getNewMoonDay(k + 1, timeZone);
  if (monthStart > dayNumber) {
    monthStart = getNewMoonDay(k, timeZone);
  }
  // Kade patch (D014, E005) — có trong reference đã patch: k ước lượng theo sóc
  // trung bình; khi sóc thực trễ và rơi vào ngày hôm sau, bản gốc trả lunarDay = 0
  // (2054-05-07, 2062-04-09). Lùi thêm 1 sóc.
  if (monthStart > dayNumber) {
    monthStart = getNewMoonDay(k - 1, timeZone);
  }
  var a11 = getLunarMonth11(yy, timeZone);
  var b11 = a11;
  int lunarYear;
  if (a11 >= monthStart) {
    lunarYear = yy;
    a11 = getLunarMonth11(yy - 1, timeZone);
  } else {
    lunarYear = yy + 1;
    b11 = getLunarMonth11(yy + 1, timeZone);
  }
  final lunarDay = dayNumber - monthStart + 1;
  final diff = INT((monthStart - a11) / 29);
  var lunarLeap = 0;
  var lunarMonth = diff + 11;
  if (b11 - a11 > 365) {
    final leapMonthDiff = getLeapMonthOffset(a11, timeZone);
    if (diff >= leapMonthDiff) {
      lunarMonth = diff + 10;
      if (diff == leapMonthDiff) {
        lunarLeap = 1;
      }
    }
  }
  if (lunarMonth > 12) {
    lunarMonth = lunarMonth - 12;
  }
  if (lunarMonth >= 11 && diff < 4) {
    lunarYear -= 1;
  }
  return (lunarDay, lunarMonth, lunarYear, lunarLeap);
}

/// Đổi ngày âm sang dương: (ngày, tháng, năm); trả (0, 0, 0) nếu đòi tháng nhuận sai.
(int day, int month, int year) convertLunar2Solar(
  int lunarDay,
  int lunarMonth,
  int lunarYear,
  int lunarLeap,
  double timeZone,
) {
  int a11, b11;
  if (lunarMonth < 11) {
    a11 = getLunarMonth11(lunarYear - 1, timeZone);
    b11 = getLunarMonth11(lunarYear, timeZone);
  } else {
    a11 = getLunarMonth11(lunarYear, timeZone);
    b11 = getLunarMonth11(lunarYear + 1, timeZone);
  }
  final k = INT(0.5 + (a11 - 2415021.076998695) / 29.530588853);
  var off = lunarMonth - 11;
  if (off < 0) {
    off += 12;
  }
  if (b11 - a11 > 365) {
    final leapOff = getLeapMonthOffset(a11, timeZone);
    var leapMonth = leapOff - 2;
    if (leapMonth < 0) {
      leapMonth += 12;
    }
    if (lunarLeap != 0 && lunarMonth != leapMonth) {
      return (0, 0, 0);
    } else if (lunarLeap != 0 || off >= leapOff) {
      off += 1;
    }
  }
  final monthStart = getNewMoonDay(k + off, timeZone);
  return jdToDate(monthStart + lunarDay - 1);
}
