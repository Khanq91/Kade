// Bao gói Export/Import JSON và file sync trên Drive (plan §2.5, D004): một
// format cho cả hai. `events` gồm cả tombstone (D025) để bước 12 merge được.
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/strings.dart';
import 'user_event.dart';

part 'sync_envelope.freezed.dart';
part 'sync_envelope.g.dart';

/// `{ "schema": 1, "exportedAt": ISO UTC, "deviceId": uuid, "events": [...] }`.
@freezed
abstract class SyncEnvelope with _$SyncEnvelope {
  const SyncEnvelope._();

  const factory SyncEnvelope({
    @Default(SyncEnvelope.currentSchema) int schema,
    required DateTime exportedAt,
    required String deviceId,
    required List<UserEvent> events,
  }) = _SyncEnvelope;

  factory SyncEnvelope.fromJson(Map<String, dynamic> json) =>
      _$SyncEnvelopeFromJson(json);

  /// Phiên bản format app hiện đọc/ghi.
  static const currentSchema = 1;

  /// Số sự kiện còn hiệu lực (không tính tombstone) — số báo cho user.
  int get activeCount => events.where((e) => !e.isDeleted).length;

  /// JSON thụt lề 2 khoảng (file cho người mở xem được).
  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Tên file xuất theo ngày máy: `kade_events_2026-09-10.json`.
  static String fileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'kade_events_${now.year}-${two(now.month)}-${two(now.day)}.json';
  }

  /// Đọc [text] thành envelope hoặc lỗi tiếng Việt: JSON hỏng; không phải
  /// object / thiếu `events` / sự kiện sai định dạng; `schema` khác [currentSchema].
  static EnvelopeParse parse(String text) {
    final Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException {
      return const EnvelopeError(Strings.backupInvalidJson);
    }
    if (raw is! Map<String, dynamic>) {
      return const EnvelopeError(Strings.backupBadFile);
    }
    final schema = raw['schema'];
    if (schema is! int) return const EnvelopeError(Strings.backupBadFile);
    if (schema != currentSchema) {
      return EnvelopeError(
        Strings.backupUnsupportedSchema(schema, currentSchema),
      );
    }
    if (raw['events'] is! List) {
      return const EnvelopeError(Strings.backupBadFile);
    }
    try {
      return EnvelopeOk(SyncEnvelope.fromJson(raw));
    } catch (_) {
      return const EnvelopeError(Strings.backupBadFile);
    }
  }
}

/// Kết quả [SyncEnvelope.parse].
sealed class EnvelopeParse {
  const EnvelopeParse();
}

/// Đọc được.
final class EnvelopeOk extends EnvelopeParse {
  const EnvelopeOk(this.envelope);

  final SyncEnvelope envelope;
}

/// Không đọc được; [message] tiếng Việt để hiện thẳng cho user.
final class EnvelopeError extends EnvelopeParse {
  const EnvelopeError(this.message);

  final String message;
}
