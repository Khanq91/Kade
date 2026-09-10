// Export/Import JSON (plan §6 bước 9): SyncEnvelope round trip, parse lỗi,
// deviceId, import ghi đè + updatedAt mới (D027), kịch bản export → xóa hết
// → import → giống hệt trừ updatedAt.
import 'dart:convert';

import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/models/sync_envelope.dart';
import 'package:kade/data/models/user_event.dart';
import 'package:kade/data/settings_provider.dart';
import 'package:kade/data/user_events_provider.dart';

import 'test_app.dart';

final _t0 = DateTime.utc(2026, 9, 10, 8);

void main() {
  group('SyncEnvelope', () {
    test(
      'round trip: tombstone, leapRule, year null, note, remindBeforeDays',
      () {
        final env = SyncEnvelope(
          exportedAt: _t0,
          deviceId: 'dev-1',
          events: [
            UserEvent(
              id: 'a',
              title: 'Giỗ ông',
              type: CalendarType.lunar,
              day: 15,
              month: 8,
              leapRule: LeapMonthRule.secondMonth,
              note: 'ghi chú',
              createdAt: _t0,
              updatedAt: _t0,
            ),
            UserEvent(
              id: 'b',
              title: 'Sinh nhật',
              type: CalendarType.solar,
              day: 6,
              month: 2,
              year: 2027,
              durationDays: 3,
              colorIndex: 4,
              createdAt: _t0,
              updatedAt: _t0,
              deletedAt: _t0,
            ),
            UserEvent(
              id: 'c',
              title: 'x',
              type: CalendarType.lunar,
              day: 1,
              month: 1,
              leapRule: LeapMonthRule.both,
              remindBeforeDays: 2,
              createdAt: _t0,
              updatedAt: _t0,
            ),
          ],
        );
        final text = env.encode();
        final json = jsonDecode(text) as Map<String, dynamic>;
        expect(json['schema'], 1);
        expect(json['exportedAt'], '2026-09-10T08:00:00.000Z');
        expect(json['deviceId'], 'dev-1');
        final events = json['events'] as List<dynamic>;
        expect(events.length, 3);
        expect(events[0]['leapRule'], 'secondMonth');
        expect(events[0]['year'], isNull);
        expect(events[1]['deletedAt'], '2026-09-10T08:00:00.000Z');

        final parsed = SyncEnvelope.parse(text);
        expect(parsed, isA<EnvelopeOk>());
        expect((parsed as EnvelopeOk).envelope, env);
        expect(env.activeCount, 2);
      },
    );

    test('fileName theo ngày máy', () {
      expect(
        SyncEnvelope.fileName(DateTime(2026, 9, 5, 23, 59)),
        'kade_events_2026-09-05.json',
      );
    });

    test('JSON hỏng / không phải Kade / schema khác → lỗi tiếng Việt', () {
      String? err(String s) => switch (SyncEnvelope.parse(s)) {
        EnvelopeError(:final message) => message,
        EnvelopeOk() => null,
      };
      const head = '"exportedAt": "2026-09-10T08:00:00Z", "deviceId": "d"';
      expect(err('{not json'), Strings.backupInvalidJson);
      expect(err(''), Strings.backupInvalidJson);
      expect(err('[]'), Strings.backupBadFile);
      expect(err('{"schema": 1, $head}'), Strings.backupBadFile);
      expect(err('{$head, "events": []}'), Strings.backupBadFile);
      expect(
        err('{"schema": 2, $head, "events": []}'),
        Strings.backupUnsupportedSchema(2, 1),
      );
      expect(
        err('{"schema": 1, $head, "events": [{"id": "x"}]}'),
        Strings.backupBadFile,
      );
      expect(err('{"schema": 1, $head, "events": []}'), isNull);
    });
  });

  group('import', () {
    Future<ProviderContainer> container() async =>
        ProviderContainer.test(overrides: await testOverrides());

    test(
      'deviceId sinh một lần, lưu box settings, đọc lại giữ nguyên',
      () async {
        final box = await memorySettingsBox();
        final c1 = ProviderContainer.test(
          overrides: await testOverrides(settingsBox: box),
        );
        final id = c1.read(deviceIdProvider);
        expect(id.length, 36);
        expect(box.get('deviceId'), id);
        final c2 = ProviderContainer.test(
          overrides: await testOverrides(settingsBox: box),
        );
        expect(c2.read(deviceIdProvider), id);
      },
    );

    test('ghi đè theo id không so updatedAt; updatedAt = now (D027)', () async {
      final c = await container();
      final notifier = c.read(userEventsProvider.notifier);
      final a = await notifier.create(
        title: 'a',
        type: CalendarType.solar,
        day: 1,
        month: 1,
      );
      // Bản trong file cũ hơn bản local vẫn thắng.
      final older = a.copyWith(title: 'b', updatedAt: _t0);
      final now = DateTime.utc(2030, 1, 1);
      await notifier.importAll([older], now: now);
      final got = c.read(userEventRepositoryProvider).get(a.id)!;
      expect(got.title, 'b');
      expect(got.updatedAt, now);
      expect(got.createdAt, a.createdAt);
      expect(c.read(activeUserEventsProvider).single.title, 'b');
    });

    test(
      '§6: 3 sự kiện → export → xóa hết → import → giống hệt trừ updatedAt',
      () async {
        final c = await container();
        final notifier = c.read(userEventsProvider.notifier);
        final e1 = await notifier.create(
          title: 'Sinh nhật',
          type: CalendarType.solar,
          day: 6,
          month: 2,
          colorIndex: 3,
        );
        final e2 = await notifier.create(
          title: 'Giỗ ông',
          type: CalendarType.lunar,
          day: 15,
          month: 8,
          note: 'ghi chú',
        );
        final e3 = await notifier.create(
          title: 'Giỗ bà',
          type: CalendarType.lunar,
          day: 15,
          month: 6,
          leapRule: LeapMonthRule.secondMonth,
          durationDays: 3,
        );
        final before = c.read(activeUserEventsProvider);
        expect(before.length, 3);

        // Export = toàn bộ box (kể cả tombstone), cùng format Drive (D004).
        final repo = c.read(userEventRepositoryProvider);
        final text = SyncEnvelope(
          exportedAt: DateTime.now().toUtc(),
          deviceId: c.read(deviceIdProvider),
          events: repo.all(),
        ).encode();

        for (final e in [e1, e2, e3]) {
          await notifier.remove(e.id);
        }
        expect(c.read(activeUserEventsProvider), isEmpty);
        expect(repo.all().where((e) => e.isDeleted).length, 3);

        final parsed = SyncEnvelope.parse(text) as EnvelopeOk;
        expect(parsed.envelope.activeCount, 3);
        final now = DateTime.utc(2030, 1, 1);
        await notifier.importAll(parsed.envelope.events, now: now);

        final after = c.read(activeUserEventsProvider);
        expect(after.every((e) => e.updatedAt == now), isTrue);
        expect(
          [for (final e in after) e.copyWith(updatedAt: _t0)],
          [for (final e in before) e.copyWith(updatedAt: _t0)],
        );
        final ids = {e1.id, e2.id, e3.id};
        expect(
          repo.all().where((e) => ids.contains(e.id) && e.isDeleted),
          isEmpty,
        );
        expect(repo.all().length, 3);
      },
    );
  });
}
