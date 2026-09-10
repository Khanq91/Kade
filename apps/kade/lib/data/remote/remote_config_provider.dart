import 'package:calendar_data/calendar_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'remote_config.dart';

/// Repository thật được override trong `main()` (cần Hive box đã mở); test
/// override bằng repo dùng MockClient.
final remoteConfigRepositoryProvider = Provider<RemoteConfigRepository>(
  (ref) => throw UnimplementedError(
    'remoteConfigRepositoryProvider phải được override trong ProviderScope',
  ),
);

/// State cho UI: overrides đang dùng + metadata.
class RemoteConfigState {
  const RemoteConfigState({
    required this.overrides,
    required this.source,
    this.fetchedAt,
    this.lastResult,
    this.checking = false,
  });

  final YearOverrides overrides;
  final ConfigSource source;
  final DateTime? fetchedAt;
  final FetchResult? lastResult;
  final bool checking;

  RemoteConfigState copyWith({
    YearOverrides? overrides,
    ConfigSource? source,
    DateTime? fetchedAt,
    FetchResult? lastResult,
    bool? checking,
  }) => RemoteConfigState(
    overrides: overrides ?? this.overrides,
    source: source ?? this.source,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    lastResult: lastResult ?? this.lastResult,
    checking: checking ?? this.checking,
  );
}

/// Load local lúc start, fetch nền nếu quá 24h (plan §3.1), fetch tay khi user bấm.
class RemoteConfigNotifier extends AsyncNotifier<RemoteConfigState> {
  @override
  Future<RemoteConfigState> build() async {
    final repo = ref.watch(remoteConfigRepositoryProvider);
    final (overrides, source) = await repo.loadLocal();
    if (repo.url.isNotEmpty && repo.isStale) {
      Future.microtask(checkForUpdates);
    }
    return RemoteConfigState(
      overrides: overrides,
      source: source,
      fetchedAt: repo.fetchedAt,
    );
  }

  /// Fetch remote; cập nhật state khi có version mới. Trả kết quả để UI báo.
  Future<FetchResult> checkForUpdates({bool force = false}) async {
    final repo = ref.read(remoteConfigRepositoryProvider);
    final current = state.value ?? await future;
    state = AsyncData(current.copyWith(checking: true));
    final result = await repo.fetch(force: force);
    final base = state.value ?? current;
    final updated = result.outcome == FetchOutcome.updated;
    state = AsyncData(
      base.copyWith(
        checking: false,
        lastResult: result,
        fetchedAt: repo.fetchedAt,
        overrides: updated ? result.overrides : null,
        source: updated ? ConfigSource.remote : null,
      ),
    );
    return result;
  }
}

/// Provider chính cho overrides (MonthView bước 6 sẽ watch để invalidate cache tháng).
final remoteConfigProvider =
    AsyncNotifierProvider<RemoteConfigNotifier, RemoteConfigState>(
      RemoteConfigNotifier.new,
    );
