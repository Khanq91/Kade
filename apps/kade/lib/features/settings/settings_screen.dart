import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env.dart';
import '../../core/formats.dart';
import '../../core/strings.dart';
import '../../data/models/sync_envelope.dart';
import '../../data/remote/remote_config.dart';
import '../../data/remote/remote_config_provider.dart';
import '../../data/settings_provider.dart';
import '../../data/user_events_provider.dart';
import '../../platform/file_io.dart';

/// Màn Cài đặt (plan §5.1): Sự kiện của tôi, Sao lưu (bước 9), khối "Lịch
/// nghỉ bù theo năm" + nút Kiểm tra cập nhật (bước 5).
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
