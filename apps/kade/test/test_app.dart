// Helper chung cho widget test: remote config giả (không HTTP), box sự kiện
// in-memory (không IO → không cần `tester.runAsync`, tránh E009) + app thật
// với router.
import 'dart:io';
import 'dart:typed_data';

import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hive_ce/hive.dart';
import 'package:kade/core/router.dart';
import 'package:kade/data/local/user_event_repository.dart';
import 'package:kade/data/remote/remote_config.dart';
import 'package:kade/data/remote/remote_config_provider.dart';
import 'package:kade/data/settings_provider.dart';
import 'package:kade/data/upcoming_provider.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:kade/main.dart';

/// Notifier giả: state sẵn sau 1 microtask, không đụng repository.
class FakeRemoteConfig extends RemoteConfigNotifier {
  FakeRemoteConfig(this.initial);

  final YearOverrides initial;

  @override
  Future<RemoteConfigState> build() async =>
      RemoteConfigState(overrides: initial, source: ConfigSource.asset);

  /// Giả lập Sheet đổi → overrides mới (test invalidate cache tháng).
  void replace(YearOverrides overrides) {
    state = AsyncData(
      RemoteConfigState(overrides: overrides, source: ConfigSource.remote),
    );
  }
}

/// Overrides từ `assets/overrides.json` (2027: nghỉ 05–09/02).
YearOverrides assetOverrides() => YearOverrides.fromJsonString(
  File('assets/overrides.json').readAsStringSync(),
);

int _boxSeq = 0;
bool _hiveReady = false;

/// Box `user_events` in-memory (Hive `bytes:`), tên duy nhất mỗi lần gọi để
/// các test không dùng chung dữ liệu. Hive vẫn đòi `init` dù không ghi file.
Future<Box<String>> memoryUserEventsBox() async {
  if (!_hiveReady) {
    Hive.init(Directory.systemTemp.path);
    _hiveReady = true;
  }
  return Hive.openBox<String>(
    'user_events_test_${_boxSeq++}',
    bytes: Uint8List(0),
  );
}

/// Box `settings` in-memory, tên duy nhất mỗi lần gọi.
Future<Box<dynamic>> memorySettingsBox() async {
  await memoryUserEventsBox(); // đảm bảo Hive.init
  return Hive.openBox<dynamic>(
    'settings_test_${_boxSeq++}',
    bytes: Uint8List(0),
  );
}

/// Override Riverpod: [FakeRemoteConfig] với [overrides] (mặc định asset),
/// repository sự kiện trên [userEventsBox], box settings [settingsBox] (mặc
/// định box in-memory mới), và [today] cho "Sắp tới" nếu truyền.
Future<List<Override>> testOverrides({
  YearOverrides? overrides,
  Box<String>? userEventsBox,
  Box<dynamic>? settingsBox,
  DateTime? today,
}) async => [
  remoteConfigProvider.overrideWith(
    () => FakeRemoteConfig(overrides ?? assetOverrides()),
  ),
  userEventRepositoryProvider.overrideWithValue(
    UserEventRepository(userEventsBox ?? await memoryUserEventsBox()),
  ),
  settingsBoxProvider.overrideWithValue(
    settingsBox ?? await memorySettingsBox(),
  ),
  if (today != null) todayProvider.overrideWithValue(today),
];

/// App thật (router + locale vi) mở tại [initialLocation].
Future<Widget> testApp(
  String initialLocation, {
  YearOverrides? overrides,
  Box<String>? userEventsBox,
  Box<dynamic>? settingsBox,
  DateTime? today,
}) async => ProviderScope(
  overrides: await testOverrides(
    overrides: overrides,
    userEventsBox: userEventsBox,
    settingsBox: settingsBox,
    today: today,
  ),
  child: KadeApp(router: createRouter(initialLocation: initialLocation)),
);
