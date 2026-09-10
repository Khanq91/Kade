// sync() với Google Drive appDataFolder (plan §3.10, D007): tải file → merge
// theo updatedAt → ghi Hive → upload nếu đổi → lưu lastSyncAt. Trigger tự động
// (start, debounce sau sửa, resume) và xử lý 401 trên web làm ở bước 13.
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../models/sync_envelope.dart';
import '../models/user_event.dart';
import '../settings_provider.dart';
import '../user_events_provider.dart';
import 'auth_provider.dart';
import 'drive_store.dart';
import 'merge.dart';

enum SyncOutcome { synced, noAuth, busy, failed }

/// Kết quả một lần [SyncNotifier.sync].
@immutable
class SyncResult {
  const SyncResult(
    this.outcome, {
    this.error,
    this.changedLocal = 0,
    this.uploaded = false,
  });

  final SyncOutcome outcome;

  /// Thông báo tiếng Việt khi không synced.
  final String? error;

  /// Số sự kiện local được thêm/ghi đè bởi bản trên Drive.
  final int changedLocal;

  /// Có ghi file lên Drive không (chỉ khi local có gì khác remote).
  final bool uploaded;
}

/// Trạng thái sync cho UI.
@immutable
class SyncState {
  const SyncState({this.running = false, this.lastSyncAt, this.lastError});

  final bool running;
  final DateTime? lastSyncAt;
  final String? lastError;
}

/// Một lần sync = find → parse → merge + purge → replaceAll → create/update.
class SyncNotifier extends Notifier<SyncState> {
  static const lastSyncKey = 'lastSyncAt';

  @override
  SyncState build() {
    final raw = ref.watch(settingsBoxProvider).get(lastSyncKey);
    return SyncState(lastSyncAt: raw is String ? DateTime.tryParse(raw) : null);
  }

  /// [interactive]: cho phép popup xin quyền Drive (web) — chỉ gọi từ thao tác
  /// của user. [now] để test cố định thời gian.
  Future<SyncResult> sync({bool interactive = false, DateTime? now}) async {
    if (state.running) {
      return const SyncResult(SyncOutcome.busy, error: Strings.syncBusy);
    }
    final token = await ref
        .read(authProvider.notifier)
        .driveToken(interactive: interactive);
    if (token == null) {
      return const SyncResult(SyncOutcome.noAuth, error: Strings.syncNoAuth);
    }
    state = SyncState(running: true, lastSyncAt: state.lastSyncAt);
    try {
      final store = ref.read(driveStoreProvider);
      final remote = await store.find(token);
      var remoteEvents = const <UserEvent>[];
      if (remote != null) {
        switch (SyncEnvelope.parse(remote.content)) {
          case EnvelopeOk(:final envelope):
            remoteEvents = envelope.events;
          case EnvelopeError(:final message):
            // Không ghi đè file lạ/hỏng — user tự xử lý (xóa dữ liệu app trên Drive).
            return _fail(Strings.syncRemoteBad(message));
        }
      }

      final local = ref.read(userEventRepositoryProvider).all();
      final t = now ?? DateTime.now().toUtc();
      final merged = purgeTombstones(mergeEvents(local, remoteEvents), t);

      var changed = 0;
      if (!sameEvents(merged, local)) {
        final before = {for (final e in local) e.id: e};
        changed = merged.where((e) => before[e.id] != e).length;
        await ref.read(userEventsProvider.notifier).replaceAll(merged);
      }

      var uploaded = false;
      if (remote == null || !sameEvents(merged, remoteEvents)) {
        final content = SyncEnvelope(
          exportedAt: t,
          deviceId: ref.read(deviceIdProvider),
          events: merged,
        ).encode();
        if (remote == null) {
          await store.create(token, content);
        } else {
          await store.update(token, remote.id, content);
        }
        uploaded = true;
      }

      await ref.read(settingsBoxProvider).put(lastSyncKey, t.toIso8601String());
      state = SyncState(lastSyncAt: t);
      return SyncResult(
        SyncOutcome.synced,
        changedLocal: changed,
        uploaded: uploaded,
      );
    } on DriveException catch (e) {
      return _fail(Strings.syncDriveError(e.status, e.message));
    } catch (e) {
      return _fail('${Strings.syncFailed} ($e)');
    }
  }

  SyncResult _fail(String message) {
    state = SyncState(lastSyncAt: state.lastSyncAt, lastError: message);
    return SyncResult(SyncOutcome.failed, error: message);
  }
}

/// Trạng thái sync Drive.
final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);
