import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kade/data/remote/remote_config.dart';

const fakeUrl = 'https://script.example.test/macros/s/x/exec';

String remoteJson(int version, {List<String> off = const ['2027-02-10']}) =>
    '{"version": $version, "updatedAt": "2026-11-20T03:00:00.000Z", '
    '"years": {"2027": {"off": [${off.map((d) => '"$d"').join(',')}], "work": []}}}';

http.Client clientReturning(String body, {int status = 200}) =>
    MockClient((_) async => http.Response(body, status));

void main() {
  late Directory tmp;
  late Box<String> box;
  final assetJson = File('assets/overrides.json').readAsStringSync();
  var assetLoads = 0;
  Future<String> loadAsset(String key) async {
    expect(key, RemoteConfigRepository.assetPath);
    assetLoads++;
    return assetJson;
  }

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('kade_rc_');
    Hive.init(tmp.path);
    box = await Hive.openBox<String>('remote_config');
    assetLoads = 0;
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  RemoteConfigRepository repo({
    String url = fakeUrl,
    http.Client? client,
    DateTime Function()? now,
  }) => RemoteConfigRepository(
    box: box,
    loadAsset: loadAsset,
    url: url,
    client: client ?? clientReturning('', status: 500),
    now: now,
    timeout: const Duration(milliseconds: 200),
  );

  test('chưa có cache → asset, version 0, chưa fetch bao giờ', () async {
    final r = repo();
    final (o, source) = await r.loadLocal();
    expect(source, ConfigSource.asset);
    expect(o.version, 0);
    expect(o.forYear(2027)!.off, hasLength(5));
    expect(r.fetchedAt, isNull);
    expect(r.cachedVersion, -1);
    expect(r.isStale, isTrue);
    expect(assetLoads, 1);
  });

  test(
    'fetch version mới → updated, lưu cache; loadLocal sau đó đọc cache',
    () async {
      final r = repo(client: clientReturning(remoteJson(1726000000000)));
      final res = await r.fetch();
      expect(res.outcome, FetchOutcome.updated);
      expect(res.overrides!.version, 1726000000000);
      expect(r.cachedVersion, 1726000000000);
      expect(r.fetchedAt, isNotNull);
      expect(r.isStale, isFalse);

      final (o, source) = await r.loadLocal();
      expect(source, ConfigSource.cache);
      expect(o.forYear(2027)!.off, {DateTime.utc(2027, 2, 10)});
      expect(assetLoads, 0);
    },
  );

  test(
    'fetch cùng / cũ hơn version cache → upToDate, chỉ cập nhật fetchedAt',
    () async {
      await repo(client: clientReturning(remoteJson(10))).fetch();
      final r = repo(client: clientReturning(remoteJson(10)));
      expect((await r.fetch(force: true)).outcome, FetchOutcome.upToDate);
      final older = repo(
        client: clientReturning(remoteJson(9, off: ['2027-03-01'])),
      );
      expect((await older.fetch(force: true)).outcome, FetchOutcome.upToDate);
      final (o, _) = await older.loadLocal();
      expect(o.version, 10);
      expect(o.forYear(2027)!.off, {DateTime.utc(2027, 2, 10)});
    },
  );

  test('chưa quá 24h và không force → skipped; quá 24h → fetch lại', () async {
    var now = DateTime.utc(2026, 9, 10, 8);
    final r = repo(client: clientReturning(remoteJson(1)), now: () => now);
    expect((await r.fetch()).outcome, FetchOutcome.updated);
    expect((await r.fetch()).outcome, FetchOutcome.skipped);
    expect((await r.fetch(force: true)).outcome, FetchOutcome.upToDate);
    now = now.add(const Duration(hours: 25));
    expect(r.isStale, isTrue);
    expect((await r.fetch()).outcome, FetchOutcome.upToDate);
  });

  test(
    'HTTP 500, HTML, JSON hỏng, timeout → failed; cache giữ nguyên',
    () async {
      await repo(client: clientReturning(remoteJson(5))).fetch();

      final cases = <String, http.Client>{
        'HTTP 500': clientReturning('oops', status: 500),
        'HTML': clientReturning('<!DOCTYPE html><html>login</html>'),
        'JSON hỏng': clientReturning('{"version": 6, "years": '),
        'JSON sai cấu trúc': clientReturning('[1, 2, 3]'),
        'timeout': MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          return http.Response(remoteJson(7), 200);
        }),
      };
      for (final entry in cases.entries) {
        final res = await repo(client: entry.value).fetch(force: true);
        expect(res.outcome, FetchOutcome.failed, reason: entry.key);
        expect(res.error, isNotEmpty, reason: entry.key);
      }
      final (o, source) = await repo().loadLocal();
      expect(source, ConfigSource.cache);
      expect(o.version, 5);
      expect(repo().cachedVersion, 5);
    },
  );

  test('không có URL → noUrl, không gọi mạng', () async {
    var calls = 0;
    final r = repo(
      url: '',
      client: MockClient((_) async {
        calls++;
        return http.Response(remoteJson(1), 200);
      }),
    );
    expect((await r.fetch(force: true)).outcome, FetchOutcome.noUrl);
    expect(calls, 0);
  });

  test('cache hỏng → rơi về asset', () async {
    await box.put('json', '{not json');
    final (o, source) = await repo().loadLocal();
    expect(source, ConfigSource.asset);
    expect(o.version, 0);
  });
}
