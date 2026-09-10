// Helper chung cho widget test bước 6: remote config giả (không Hive, không
// HTTP → không cần `tester.runAsync`, tránh E009) + app thật với router.
import 'dart:io';

import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kade/core/router.dart';
import 'package:kade/data/remote/remote_config.dart';
import 'package:kade/data/remote/remote_config_provider.dart';
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

/// Override Riverpod dùng [FakeRemoteConfig] với [overrides] (mặc định asset).
List<Override> fakeRemoteConfig([YearOverrides? overrides]) => [
  remoteConfigProvider.overrideWith(
    () => FakeRemoteConfig(overrides ?? assetOverrides()),
  ),
];

/// App thật (router + locale vi) mở tại [initialLocation].
Widget testApp(String initialLocation, {YearOverrides? overrides}) =>
    ProviderScope(
      overrides: fakeRemoteConfig(overrides),
      child: KadeApp(router: createRouter(initialLocation: initialLocation)),
    );
