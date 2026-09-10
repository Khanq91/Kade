// Sự kiện cá nhân (plan §2.4). Lưu Hive dạng JSON (D025), cùng format với
// SyncEnvelope (bước 9/12). Xóa = tombstone `deletedAt` (D007), không xóa cứng.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_event.freezed.dart';
part 'user_event.g.dart';

/// Quy tắc tháng nhuận cho sự kiện âm lịch (D005): năm có tháng nhuận trùng
/// tháng → lấy tháng chính / tháng nhuận / cả hai. Năm không nhuận → luôn tháng chính.
enum LeapMonthRule { firstMonth, secondMonth, both }

/// Sự kiện cá nhân. [year] null = lặp hàng năm.
@freezed
abstract class UserEvent with _$UserEvent {
  const UserEvent._();

  const factory UserEvent({
    required String id,
    required String title,
    required CalendarType type,
    required int day,
    required int month,
    int? year,
    @Default(1) int durationDays,
    @Default(LeapMonthRule.firstMonth) LeapMonthRule leapRule,
    int? remindBeforeDays,
    String? note,
    @Default(0) int colorIndex,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _UserEvent;

  factory UserEvent.fromJson(Map<String, dynamic> json) =>
      _$UserEventFromJson(json);

  /// Đã xóa mềm (tombstone).
  bool get isDeleted => deletedAt != null;

  /// Lặp hàng năm.
  bool get isYearly => year == null;
}
