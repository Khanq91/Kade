import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kade/core/strings.dart';
import 'package:kade/data/remote/remote_config.dart';
import 'package:kade/data/remote/remote_config_provider.dart';
import 'package:kade/features/settings/settings_screen.dart';

// Hive ghi file thật → phải chạy trong `tester.runAsync`, nếu không IO bị kẹt
// trong FakeAsync của testWidgets và `Hive.close()` ở tearDown treo (ERRORS E009).
void main() {
  late Directory tmp;
  late Box<String> box;
  final assetJson = File('assets/overrides.json').readAsStringSync();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('kade_settings_');
    Hive.init(tmp.path);
    box = await Hive.openBox<String>('remote_config');
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Widget app(RemoteConfigRepository repo) => ProviderScope(
    overrides: [remoteConfigRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: SettingsScreen()),
  );

  /// Pump tới khi hết spinner (tối đa ~5s thời gian thật).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.text(Strings.checking).evaluate().isEmpty) {
        await tester.pump();
        return;
      }
    }
    fail('UI không settle');
  }

  testWidgets('không có URL: hiện dữ liệu asset + cảnh báo, nút bị tắt', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final repo = RemoteConfigRepository(
        box: box,
        loadAsset: (_) async => assetJson,
        url: '',
        client: MockClient((_) async => http.Response('', 500)),
      );
      await tester.pumpWidget(app(repo));
      await settle(tester);

      expect(find.text(Strings.sourceAsset), findsOneWidget);
      // Tile năm nằm dưới viewport 800x600 của test → cuộn tới trước khi assert.
      await tester.ensureVisible(
        find.text(Strings.yearTitle(2027), skipOffstage: false),
      );
      await tester.pump();
      expect(find.text(Strings.yearTitle(2027)), findsOneWidget);
      expect(find.textContaining('05/02/2027'), findsOneWidget);
      // Env.configUrl rỗng trong test → cảnh báo + nút disabled.
      expect(find.text(Strings.noConfigUrl), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  testWidgets(
    'có URL: tự fetch lúc start (quá 24h) → nguồn = remote, version mới',
    (tester) async {
      await tester.runAsync(() async {
        var calls = 0;
        final repo = RemoteConfigRepository(
          box: box,
          loadAsset: (_) async => assetJson,
          url: 'https://script.example.test/exec',
          client: MockClient((_) async {
            calls++;
            return http.Response(
              '{"version": 42, "updatedAt": "2026-11-20T03:00:00.000Z",'
              ' "years": {"2028": {"off": ["2028-01-25"], "work": ["2028-02-05"]}}}',
              200,
            );
          }),
        );
        await tester.pumpWidget(app(repo));
        await settle(tester);

        expect(calls, 1);
        expect(find.text(Strings.sourceRemote), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
        await tester.ensureVisible(
          find.text(Strings.yearTitle(2028), skipOffstage: false),
        );
        await tester.pump();
        expect(find.text(Strings.yearTitle(2028)), findsOneWidget);
        expect(find.textContaining('25/01/2028'), findsOneWidget);
        expect(find.textContaining('05/02/2028'), findsOneWidget);
        expect(
          find.text(Strings.yearTitle(2027), skipOffstage: false),
          findsNothing,
        );
        expect(repo.cachedVersion, 42);
      });
    },
  );

  test('fetchResultText đủ 5 outcome', () {
    expect(
      fetchResultText(const FetchResult(FetchOutcome.updated)),
      Strings.fetchUpdated,
    );
    expect(
      fetchResultText(const FetchResult(FetchOutcome.upToDate)),
      Strings.fetchUpToDate,
    );
    expect(
      fetchResultText(const FetchResult(FetchOutcome.skipped)),
      Strings.fetchSkipped,
    );
    expect(
      fetchResultText(const FetchResult(FetchOutcome.noUrl)),
      Strings.noConfigUrl,
    );
    expect(
      fetchResultText(
        const FetchResult(FetchOutcome.failed, error: 'HTTP 500'),
      ),
      contains('HTTP 500'),
    );
  });
}
