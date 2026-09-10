import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/formats.dart';
import '../../core/strings.dart';
import '../../data/remote/remote_config.dart';
import '../../data/remote/remote_config_provider.dart';

/// Màn Cài đặt. Bước 5: khối "Lịch nghỉ bù theo năm" + nút Kiểm tra cập nhật.
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
