// sync() (plan §3.10) với DriveStore + GoogleAuth giả: tạo file khi Drive
// trống, nhận sự kiện từ Drive, 2 chiều theo updatedAt, tombstone thắng, không
// có token, file Drive hỏng, lỗi Drive 401, purge tombstone > 90 ngày.
import 'package:calendar_data/calendar_data.dart' show CalendarType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kade/data/local/user_event_repository.dart';
import 'package:kade/data/models/sync_envelope.dart';
import 'package:kade/data/models/user_event.dart';
import 'package:kade/data/sync/auth_provider.dart';
import 'package:kade/data/sync/drive_store.dart';
import 'package:kade/data/sync/sync_provider.dart';
import 'package:kade/data/user_events_provider.dart';

import 'test_app.dart';

final _t1 = DateTime.utc(2026, 9, 1);
final _t2 = DateTime.utc(2026, 9, 2);
final _now = DateTime.utc(2026, 9, 10, 12);

UserEvent _ev(
  String id, {
  String title = 't',
  required DateTime updatedAt,
  DateTime? deletedAt,
}) => UserEvent(
  id: id,
  title: title,
  type: CalendarType.lunar,
  day: 15,
  month: 8,
  createdAt: _t1,
  updatedAt: updatedAt,
  deletedAt: deletedAt,
);

String _envelope(List<UserEvent> events) => SyncEnvelope(
  exportedAt: _t1,
  deviceId: 'other-device',
  events: events,
).encode();

List<UserEvent> _events(String content) =>
    (SyncEnvelope.parse(content) as EnvelopeOk).envelope.events;

void main() {
  late FakeGoogleAuth auth;
  late FakeDriveStore store;
  late Box<String> box;
  late ProviderContainer c;

  /// Container đã đăng nhập (Android-like, token im lặng sẵn).
  Future<void> setUpSignedIn({List<UserEvent> local = const []}) async {
    auth = FakeGoogleAuth()..silentToken = 'tok';
    store = FakeDriveStore();
    box = await memoryUserEventsBox();
    await UserEventRepository(box).putAll(local);
    c = ProviderContainer.test(
      overrides: await testOverrides(
        googleAuth: auth,
        driveStore: store,
        userEventsBox: box,
      ),
    );
    c.read(authProvider);
    auth.emitSignIn(auth.signInUser);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(authProvider).signedIn, isTrue);
  }

  Future<SyncResult> sync() => c.read(syncProvider.notifier).sync(now: _now);

  test(
    'Drive trống + local có → tạo file với toàn bộ local, lastSyncAt',
    () async {
      final a = _ev('a', updatedAt: _t1);
      await setUpSignedIn(local: [a]);
      final r = await sync();
      expect(r.outcome, SyncOutcome.synced);
      expect(r.uploaded, isTrue);
      expect(r.changedLocal, 0);
      expect(store.calls, ['find', 'create']);
      expect(store.tokens.toSet(), {'tok'});
      expect(_events(store.file!.content), [a]);
      expect(c.read(syncProvider).lastSyncAt, _now);
      expect(c.read(syncProvider).running, isFalse);
      expect(c.read(authProvider).driveGranted, isTrue);

      // Không đổi gì → lần sau chỉ find, không upload.
      final r2 = await sync();
      expect(r2.uploaded, isFalse);
      expect(store.calls, ['find', 'create', 'find']);
    },
  );

  test(
    'chỉ remote có → local nhận, không upload; hiện ở activeUserEvents',
    () async {
      await setUpSignedIn();
      final r0 = _ev('r', title: 'Từ Drive', updatedAt: _t1);
      store.file = RemoteFile(id: 'f9', content: _envelope([r0]));
      final r = await sync();
      expect(r.outcome, SyncOutcome.synced);
      expect(r.changedLocal, 1);
      expect(r.uploaded, isFalse);
      expect(store.calls, ['find']);
      expect(c.read(activeUserEventsProvider).single.title, 'Từ Drive');
      expect(UserEventRepository(box).get('r'), r0); // giữ nguyên updatedAt
    },
  );

  test(
    'cả 2: local mới hơn → upload local; remote mới hơn → local bị ghi đè',
    () async {
      final localNew = _ev('a', title: 'local', updatedAt: _t2);
      final localOld = _ev('b', title: 'local', updatedAt: _t1);
      await setUpSignedIn(local: [localNew, localOld]);
      store.file = RemoteFile(
        id: 'f1',
        content: _envelope([
          _ev('a', title: 'remote', updatedAt: _t1),
          _ev('b', title: 'remote', updatedAt: _t2),
        ]),
      );
      final r = await sync();
      expect(r.outcome, SyncOutcome.synced);
      expect(r.changedLocal, 1);
      expect(r.uploaded, isTrue);
      expect(store.calls, ['find', 'update']);
      final titles = {
        for (final e in c.read(activeUserEventsProvider)) e.id: e.title,
      };
      expect(titles, {'a': 'local', 'b': 'remote'});
      final remoteTitles = {
        for (final e in _events(store.file!.content)) e.id: e.title,
      };
      expect(remoteTitles, {'a': 'local', 'b': 'remote'});
    },
  );

  test(
    'tombstone thắng: remote xóa mới hơn → local ẩn, không resurrect',
    () async {
      await setUpSignedIn(local: [_ev('a', updatedAt: _t1)]);
      store.file = RemoteFile(
        id: 'f1',
        content: _envelope([_ev('a', updatedAt: _t2, deletedAt: _t2)]),
      );
      final r = await sync();
      expect(r.changedLocal, 1);
      expect(r.uploaded, isFalse);
      expect(c.read(activeUserEventsProvider), isEmpty);
      expect(UserEventRepository(box).get('a')!.isDeleted, isTrue);

      // Chiều ngược: local xóa mới hơn → upload tombstone.
      store.file = RemoteFile(
        id: 'f1',
        content: _envelope([_ev('a', updatedAt: _t1)]),
      );
      final t3 = _t2.add(const Duration(days: 1));
      await UserEventRepository(
        box,
      ).put(_ev('a', updatedAt: t3, deletedAt: t3));
      final r2 = await sync();
      expect(r2.uploaded, isTrue);
      expect(_events(store.file!.content).single.isDeleted, isTrue);
    },
  );

  test('chưa đăng nhập / không token → noAuth, không gọi Drive', () async {
    store = FakeDriveStore();
    c = ProviderContainer.test(
      overrides: await testOverrides(driveStore: store),
    );
    final r = await sync();
    expect(r.outcome, SyncOutcome.noAuth);
    expect(store.calls, isEmpty);
  });

  test('file Drive hỏng → failed, không ghi đè, local giữ nguyên', () async {
    final a = _ev('a', updatedAt: _t1);
    await setUpSignedIn(local: [a]);
    store.file = const RemoteFile(
      id: 'f1',
      content: '{"schema": 2, "events": []}',
    );
    final r = await sync();
    expect(r.outcome, SyncOutcome.failed);
    expect(r.error, contains('không đọc được'));
    expect(store.calls, ['find']);
    expect(UserEventRepository(box).all(), [a]);
    expect(c.read(syncProvider).lastError, r.error);
    expect(c.read(syncProvider).lastSyncAt, isNull);
  });

  test('Drive 401 → failed có mã, running về false', () async {
    await setUpSignedIn(local: [_ev('a', updatedAt: _t1)]);
    store.error = DriveException(401, 'Invalid Credentials');
    final r = await sync();
    expect(r.outcome, SyncOutcome.failed);
    expect(r.error, contains('401'));
    expect(c.read(syncProvider).running, isFalse);
    expect(c.read(syncProvider).lastError, contains('Invalid Credentials'));
  });

  test('purge: tombstone > 90 ngày bị xóa cứng và không lên Drive', () async {
    final old = _ev(
      'old',
      updatedAt: _t1,
      deletedAt: _now.subtract(const Duration(days: 100)),
    );
    final live = _ev('a', updatedAt: _t1);
    await setUpSignedIn(local: [old, live]);
    final r = await sync();
    expect(r.outcome, SyncOutcome.synced);
    expect(UserEventRepository(box).all(), [live]);
    expect(_events(store.file!.content), [live]);
  });
}
