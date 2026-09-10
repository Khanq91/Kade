// Remote config nghỉ bù (plan §2.3, §3.9, D008): GET Apps Script → so version
// với cache → lưu Hive; lỗi → im lặng dùng cache; chưa có cache → asset.
import 'dart:convert';
import 'dart:developer';

import 'package:calendar_data/calendar_data.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

/// Dữ liệu overrides hiện tại đến từ đâu.
enum ConfigSource { none, asset, cache, remote }

/// Kết quả một lần [RemoteConfigRepository.fetch].
enum FetchOutcome { updated, upToDate, skipped, noUrl, failed }

/// Kết quả fetch kèm dữ liệu (khi có) hoặc lỗi (khi failed).
class FetchResult {
  const FetchResult(this.outcome, {this.overrides, this.error});

  final FetchOutcome outcome;

  /// Dữ liệu remote đã parse (updated / upToDate).
  final YearOverrides? overrides;

  /// Mô tả lỗi ngắn (failed).
  final String? error;

  @override
  String toString() =>
      'FetchResult($outcome${error == null ? '' : ', $error'})';
}

/// Đọc/ghi cache Hive, asset fallback và fetch remote. Không giữ state UI.
class RemoteConfigRepository {
  RemoteConfigRepository({
    required this.box,
    required this.loadAsset,
    required this.url,
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
    this.maxAge = const Duration(hours: 24),
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  /// Đường dẫn asset fallback trong app.
  static const assetPath = 'assets/overrides.json';

  static const _keyJson = 'json';
  static const _keyVersion = 'version';
  static const _keyFetchedAt = 'fetchedAt';
  static const _logName = 'kade.remote_config';

  /// Box `remote_config` (đã mở).
  final Box<String> box;

  /// Đọc asset theo key (app: `rootBundle.loadString`).
  final Future<String> Function(String key) loadAsset;

  /// URL Apps Script; rỗng = tắt fetch.
  final String url;

  /// Timeout mỗi lần GET (plan §3.9: 5s).
  final Duration timeout;

  /// Khoảng cách tối thiểu giữa 2 lần fetch tự động (plan §2.3: 24h).
  final Duration maxAge;

  final http.Client _client;
  final DateTime Function() _now;

  /// Lần fetch thành công gần nhất (updated hoặc upToDate), hoặc `null`.
  DateTime? get fetchedAt => DateTime.tryParse(box.get(_keyFetchedAt) ?? '');

  /// Version đang cache; -1 nếu chưa có.
  int get cachedVersion => int.tryParse(box.get(_keyVersion) ?? '') ?? -1;

  /// Chưa fetch bao giờ hoặc đã quá [maxAge].
  bool get isStale {
    final t = fetchedAt;
    return t == null || _now().difference(t) > maxAge;
  }

  /// Dữ liệu local: cache Hive → asset → rỗng.
  Future<(YearOverrides, ConfigSource)> loadLocal() async {
    final cached = box.get(_keyJson);
    if (cached != null) {
      try {
        return (YearOverrides.fromJsonString(cached), ConfigSource.cache);
      } on FormatException catch (e) {
        log('Cache hỏng, bỏ qua: $e', name: _logName);
      }
    }
    try {
      final asset = await loadAsset(assetPath);
      return (YearOverrides.fromJsonString(asset), ConfigSource.asset);
    } catch (e, s) {
      log('Không đọc được asset', error: e, stackTrace: s, name: _logName);
      return (YearOverrides.empty, ConfigSource.none);
    }
  }

  /// GET [url]; lưu cache nếu version mới hơn. [force] bỏ qua kiểm tra [maxAge].
  Future<FetchResult> fetch({bool force = false}) async {
    if (url.isEmpty) return const FetchResult(FetchOutcome.noUrl);
    if (!force && !isStale) return const FetchResult(FetchOutcome.skipped);

    final String body;
    try {
      final res = await _client.get(Uri.parse(url)).timeout(timeout);
      if (res.statusCode != 200) {
        return FetchResult(
          FetchOutcome.failed,
          error: 'HTTP ${res.statusCode}',
        );
      }
      body = utf8.decode(res.bodyBytes);
    } catch (e) {
      log('Fetch lỗi: $e', name: _logName);
      return FetchResult(FetchOutcome.failed, error: '$e');
    }

    if (body.trimLeft().startsWith('<')) {
      return const FetchResult(
        FetchOutcome.failed,
        error:
            'Nhận HTML thay vì JSON — kiểm tra deploy "Who has access: Anyone"',
      );
    }
    final YearOverrides parsed;
    try {
      parsed = YearOverrides.fromJsonString(body);
    } on FormatException catch (e) {
      return FetchResult(
        FetchOutcome.failed,
        error: 'JSON không hợp lệ: ${e.message}',
      );
    } on TypeError catch (e) {
      return FetchResult(FetchOutcome.failed, error: 'JSON sai cấu trúc: $e');
    }

    final nowIso = _now().toUtc().toIso8601String();
    if (parsed.version > cachedVersion) {
      await box.putAll({
        _keyJson: body,
        _keyVersion: '${parsed.version}',
        _keyFetchedAt: nowIso,
      });
      return FetchResult(FetchOutcome.updated, overrides: parsed);
    }
    await box.put(_keyFetchedAt, nowIso);
    return FetchResult(FetchOutcome.upToDate, overrides: parsed);
  }
}
