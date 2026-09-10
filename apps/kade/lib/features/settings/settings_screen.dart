import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env.dart';
import '../../core/formats.dart';
import '../../core/strings.dart';
import '../../data/models/sync_envelope.dart';
import '../../data/reminder_scheduler.dart';
import '../../data/remote/remote_config.dart';
import '../../data/remote/remote_config_provider.dart';
import '../../data/settings_provider.dart';
import '../../data/sync/auth_provider.dart';
import '../../data/sync/google_auth.dart';
import '../../data/sync/sync_provider.dart';
import '../../data/user_events_provider.dart';
import '../../platform/file_io.dart';
import '../../platform/sign_in_button.dart';

/// Màn Cài đặt (plan §5.1): Sự kiện của tôi, Đồng bộ Google (bước 11), Sao
/// lưu (bước 9), khối "Lịch nghỉ bù theo năm" + nút Kiểm tra cập nhật (bước 5).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(remoteConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settingsTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${Strings.loadError}: $e')),
        data: (s) => _RemoteConfigSection(state: s),
      ),
    );
  }
}

class _RemoteConfigSection extends ConsumerWidget {
  const _RemoteConfigSection({required this.state});

  final RemoteConfigState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final years = state.overrides.years.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: const Icon(Icons.event_note_outlined),
          title: const Text(Strings.myEvents),
          subtitle: const Text(Strings.myEventsHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/events'),
        ),
        const Divider(),
        // Nhắc nhở chỉ có trên Android (plan §4.6: web không nhắc).
        if (!ref.watch(platformIsWebProvider)) ...[
          const _RemindSection(),
          const Divider(),
        ],
        const _SyncSection(),
        const Divider(),
        const _BackupSection(),
        const Divider(),
        const ListTile(
          title: Text(Strings.remoteConfigSection),
          subtitle: Text(Strings.remoteConfigHint),
        ),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text(Strings.sourceLabel),
          subtitle: Text(_sourceText(state.source)),
        ),
        ListTile(
          leading: const Icon(Icons.tag),
          title: const Text(Strings.versionLabel),
          subtitle: Text('${state.overrides.version}'),
        ),
        ListTile(
          leading: const Icon(Icons.edit_calendar_outlined),
          title: const Text(Strings.updatedAtLabel),
          subtitle: Text(
            state.overrides.updatedAt == null
                ? Strings.unknown
                : formatDateTime(state.overrides.updatedAt!),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.sync_outlined),
          title: const Text(Strings.fetchedAtLabel),
          subtitle: Text(
            state.fetchedAt == null
                ? Strings.never
                : formatDateTime(state.fetchedAt!),
          ),
        ),
        if (!Env.hasConfigUrl)
          const ListTile(
            leading: Icon(Icons.warning_amber_outlined),
            title: Text(Strings.noConfigUrl),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FilledButton.icon(
            onPressed: state.checking || !Env.hasConfigUrl
                ? null
                : () => _check(context, ref),
            icon: const Icon(Icons.refresh),
            label: Text(
              state.checking ? Strings.checking : Strings.checkUpdates,
            ),
          ),
        ),
        const Divider(),
        if (years.isEmpty)
          const ListTile(title: Text(Strings.noOverrides))
        else
          for (final y in years)
            _YearTile(year: y, data: state.overrides.years[y]!),
      ],
    );
  }

  Future<void> _check(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(remoteConfigProvider.notifier)
        .checkForUpdates(force: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(fetchResultText(result))));
  }
}

/// Mục "Nhắc nhở" (plan §5.1, bước 16): "Nhắc lễ trước N ngày" (0 = không).
/// Chọn > 0 → xin quyền thông báo ngay lúc đó (plan §5.4).
class _RemindSection extends ConsumerWidget {
  const _RemindSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(holidayRemindDaysProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListTile(
          title: Text(Strings.remindSection),
          subtitle: Text(Strings.remindHint),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text(Strings.remindHolidayLabel),
          trailing: DropdownButton<int>(
            key: const ValueKey('remind-holiday'),
            value: days,
            items: [
              for (final o in HolidayRemindDaysNotifier.options)
                DropdownMenuItem(
                  value: o,
                  child: Text(
                    o == 0 ? Strings.remindNone : Strings.remindDaysBefore(o),
                  ),
                ),
            ],
            onChanged: (v) => v == null ? null : _set(context, ref, v),
          ),
        ),
      ],
    );
  }

  Future<void> _set(BuildContext context, WidgetRef ref, int days) async {
    await ref.read(holidayRemindDaysProvider.notifier).set(days);
    if (days == 0 || !context.mounted) return;
    final ok = await ref.read(reminderSchedulerProvider).requestPermission();
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(Strings.notificationsDenied)),
      );
  }
}

/// Mục "Đồng bộ Google" (plan §3.10, bước 11–12): đăng nhập + quyền Drive
/// appData + "Đồng bộ ngay". Android: nút của app → `authenticate()` rồi xin
/// quyền luôn. Web: nút GIS (`googleSignInButton`); "Đồng bộ ngay" xin quyền
/// Drive (popup) ngay trong thao tác đó nếu phiên chưa có token.
class _SyncSection extends ConsumerWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final sync = ref.watch(syncProvider);
    final user = auth.user;
    final error = auth.error ?? sync.lastError;
    final notifier = ref.read(authProvider.notifier);
    final busy = auth.busy || sync.running;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListTile(
          title: Text(Strings.syncSection),
          subtitle: Text(Strings.syncHint),
        ),
        if (!auth.configured)
          const ListTile(
            leading: Icon(Icons.warning_amber_outlined),
            title: Text(Strings.noWebClientId),
          )
        else if (user != null) ...[
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(user.displayName ?? user.email),
            subtitle: Text(user.email),
          ),
          ListTile(
            key: const ValueKey('sync-drive-status'),
            leading: Icon(
              auth.driveGranted
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
            ),
            title: Text(
              auth.driveGranted
                  ? Strings.driveGranted
                  : Strings.driveNotGranted,
            ),
          ),
          ListTile(
            key: const ValueKey('sync-last'),
            leading: const Icon(Icons.history),
            title: Text(
              sync.lastSyncAt == null
                  ? Strings.neverSynced
                  : Strings.lastSync(formatDateTime(sync.lastSyncAt!)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const ValueKey('sync-now'),
                  onPressed: busy ? null : () => _syncNow(context, ref),
                  icon: sync.running
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(sync.running ? Strings.syncing : Strings.syncNow),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('sync-signout'),
                  onPressed: busy ? null : notifier.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text(Strings.signOut),
                ),
                TextButton.icon(
                  key: const ValueKey('sync-delete-remote'),
                  onPressed: busy ? null : () => _deleteRemote(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(Strings.deleteRemote),
                ),
              ],
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: auth.busy
                ? const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(Strings.signingIn),
                    ],
                  )
                : ref.watch(googleAuthProvider).supportsAuthenticate
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      key: const ValueKey('sync-signin'),
                      onPressed: notifier.signIn,
                      icon: const Icon(Icons.login),
                      label: const Text(Strings.signInGoogle),
                    ),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: googleSignInButton(),
                  ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              error,
              key: const ValueKey('sync-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  /// "Đồng bộ ngay": interactive để web xin quyền Drive ngay trong click này.
  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final r = await ref.read(syncProvider.notifier).sync(interactive: true);
    if (!context.mounted) return;
    final text = switch (r.outcome) {
      SyncOutcome.synced =>
        r.changedLocal > 0
            ? Strings.syncDoneChanged(r.changedLocal)
            : Strings.syncDone,
      SyncOutcome.noAuth => Strings.syncNoAuth,
      SyncOutcome.busy => Strings.syncBusy,
      SyncOutcome.failed => r.error ?? Strings.syncFailed,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// "Xóa dữ liệu trên Drive" (plan §3.10): xác nhận → xóa file → đăng xuất.
  Future<void> _deleteRemote(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Strings.deleteRemoteTitle),
        content: const Text(Strings.deleteRemoteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(Strings.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await ref.read(syncProvider.notifier).deleteRemote();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error ?? Strings.deleteRemoteDone)),
      );
  }
}

/// Mục "Sao lưu": xuất / nhập file JSON dạng `SyncEnvelope` (D004, D027).
/// Không watch provider nào lúc build — chỉ đọc khi bấm nút.
class _BackupSection extends ConsumerWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListTile(
          title: Text(Strings.backupSection),
          subtitle: Text(Strings.backupHint),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('backup-export'),
                onPressed: () => _export(context, ref),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text(Strings.exportJson),
              ),
              OutlinedButton.icon(
                key: const ValueKey('backup-import'),
                onPressed: () => _import(context, ref),
                icon: const Icon(Icons.file_open_outlined),
                label: const Text(Strings.importJson),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Xuất toàn bộ box (kể cả tombstone, D025) → file `kade_events_YYYY-MM-DD.json`.
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final envelope = SyncEnvelope(
      exportedAt: DateTime.now().toUtc(),
      deviceId: ref.read(deviceIdProvider),
      events: ref.read(userEventRepositoryProvider).all(),
    );
    final bool saved;
    try {
      saved = await ref
          .read(fileIoProvider)
          .saveJson(SyncEnvelope.fileName(DateTime.now()), envelope.encode());
    } catch (e) {
      if (context.mounted) _snack(context, '${Strings.exportFailed} ($e)');
      return;
    }
    if (!saved || !context.mounted) return;
    _snack(context, Strings.exported(envelope.activeCount));
  }

  /// Chọn file → parse → dialog xác nhận → ghi đè theo id (D027).
  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final String? text;
    try {
      text = await ref.read(fileIoProvider).pickJson();
    } catch (e) {
      if (context.mounted) _snack(context, '${Strings.importFailed} ($e)');
      return;
    }
    if (text == null || !context.mounted) return;
    switch (SyncEnvelope.parse(text)) {
      case EnvelopeError(:final message):
        _snack(context, message);
      case EnvelopeOk(:final envelope):
        final n = envelope.activeCount;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(Strings.importConfirmTitle(n)),
            content: const Text(Strings.importConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(Strings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(Strings.importButton),
              ),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
        await ref.read(userEventsProvider.notifier).importAll(envelope.events);
        if (!context.mounted) return;
        _snack(context, Strings.imported(n));
    }
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _YearTile extends StatelessWidget {
  const _YearTile({required this.year, required this.data});

  final int year;
  final YearOverride data;

  @override
  Widget build(BuildContext context) {
    String dates(Set<DateTime> s) =>
        (s.toList()..sort()).map(formatDate).join(', ');
    return ListTile(
      leading: const Icon(Icons.calendar_month_outlined),
      title: Text(Strings.yearTitle(year)),
      subtitle: Text(
        '${Strings.offDays}: ${data.off.isEmpty ? '—' : dates(data.off)}\n'
        '${Strings.workDays}: ${data.work.isEmpty ? '—' : dates(data.work)}',
      ),
      isThreeLine: true,
    );
  }
}

String _sourceText(ConfigSource s) => switch (s) {
  ConfigSource.none => Strings.sourceNone,
  ConfigSource.asset => Strings.sourceAsset,
  ConfigSource.cache => Strings.sourceCache,
  ConfigSource.remote => Strings.sourceRemote,
};

/// Câu báo cho user sau một lần kiểm tra cập nhật.
String fetchResultText(FetchResult r) => switch (r.outcome) {
  FetchOutcome.updated => Strings.fetchUpdated,
  FetchOutcome.upToDate => Strings.fetchUpToDate,
  FetchOutcome.skipped => Strings.fetchSkipped,
  FetchOutcome.noUrl => Strings.noConfigUrl,
  FetchOutcome.failed => '${Strings.fetchFailed} (${r.error})',
};
