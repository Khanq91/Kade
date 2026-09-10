// Helper chung cho widget test: remote config giả (không HTTP), box sự kiện
// in-memory (không IO → không cần `tester.runAsync`, tránh E009), FileIo giả,
// GoogleAuth giả + app thật với router; `testTall` cho màn dài (E009).
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kade/core/router.dart';
import 'package:kade/data/local/user_event_repository.dart';
import 'package:kade/data/remote/remote_config.dart';
import 'package:kade/data/remote/remote_config_provider.dart';
import 'package:kade/data/settings_provider.dart';
import 'package:kade/data/sync/drive_store.dart';
import 'package:kade/data/sync/google_auth.dart';
import 'package:kade/data/upcoming_provider.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:kade/main.dart';
import 'package:kade/platform/file_io.dart';

/// GoogleAuth giả. Android-like mặc định (`supportsAuthenticate` true):
/// [signIn] trả [signInUser] hoặc throw [signInError]. Web-like
/// (`supportsAuthenticate: false`): test gọi [emitSignIn] thay nút GIS.
/// [accessToken]: có [silentToken] → trả luôn; không thì chỉ khi interactive
/// (đếm [interactiveCalls]) hoặc throw [authorizeError].
class FakeGoogleAuth implements GoogleAuth {
  FakeGoogleAuth({this.supportsAuthenticate = true, this.isConfigured = true});

  @override
  final bool supportsAuthenticate;

  @override
  final bool isConfigured;

  final _events = StreamController<AuthUser?>.broadcast();

  /// Giá trị `restore` của lần [init] gần nhất; null = chưa init.
  bool? initRestore;

  AuthUser? current;
  AuthUser signInUser = const AuthUser(
    id: 'u1',
    email: 'a@gmail.com',
    displayName: 'Nguyễn A',
  );
  Object? signInError;
  Object? authorizeError;
  String? silentToken;
  int interactiveCalls = 0;

  @override
  Stream<AuthUser?> get userChanges => _events.stream;

  @override
  Future<void> init({required bool restore}) async {
    initRestore = restore;
  }

  /// Giả lập nút GIS trên web / khôi phục im lặng: đẩy sự kiện đăng nhập.
  void emitSignIn(AuthUser user) {
    current = user;
    _events.add(user);
  }

  @override
  Future<AuthUser> signIn() async {
    final e = signInError;
    if (e != null) throw e;
    current = signInUser;
    _events.add(signInUser);
    return signInUser;
  }

  @override
  Future<void> signOut() async {
    current = null;
    _events.add(null);
  }

  @override
  Future<String?> accessToken({bool interactive = false}) async {
    if (current == null) return null;
    if (silentToken != null) return silentToken;
    if (!interactive) return null;
    final e = authorizeError;
    if (e != null) throw e;
    interactiveCalls++;
    return 'tok-$interactiveCalls';
  }
}

/// FileIo giả: `saveJson` ghi lại (tên, nội dung) vào [saved] và trả
/// [saveResult]; `pickJson` trả [pickResult] (null = user hủy).
class FakeFileIo implements FileIo {
  String? pickResult;
  bool saveResult = true;
  final saved = <(String, String)>[];

  @override
  Future<String?> pickJson() async => pickResult;

  @override
  Future<bool> saveJson(String name, String content) async {
    saved.add((name, content));
    return saveResult;
  }
}

/// DriveStore giả: [file] là "file trên Drive"; ghi lại [calls] và [tokens];
/// [error] → ném ở mọi lệnh (giả 401…).
class FakeDriveStore implements DriveStore {
  RemoteFile? file;
  DriveException? error;
  final calls = <String>[];
  final tokens = <String>[];

  void _check(String token, String op) {
    tokens.add(token);
    calls.add(op);
    final e = error;
    if (e != null) throw e;
  }

  @override
  Future<RemoteFile?> find(String token) async {
    _check(token, 'find');
    return file;
  }

  @override
  Future<String> create(String token, String content) async {
    _check(token, 'create');
    file = RemoteFile(id: 'f1', content: content);
    return 'f1';
  }

  @override
  Future<void> update(String token, String id, String content) async {
    _check(token, 'update');
    file = RemoteFile(id: id, content: content);
  }
}

/// testWidgets với viewport 800×1600 để form/DayDetail/Settings không bị
/// offstage (E009).
void testTall(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await callback(tester);
  });
}

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
/// định box in-memory mới), [fileIo] (mặc định [FakeFileIo] mới), [googleAuth]
/// (mặc định [FakeGoogleAuth] mới), [driveStore] (mặc định [FakeDriveStore]
/// mới) và [today] cho "Sắp tới" nếu truyền.
Future<List<Override>> testOverrides({
  YearOverrides? overrides,
  Box<String>? userEventsBox,
  Box<dynamic>? settingsBox,
  FileIo? fileIo,
  GoogleAuth? googleAuth,
  DriveStore? driveStore,
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
  fileIoProvider.overrideWithValue(fileIo ?? FakeFileIo()),
  googleAuthProvider.overrideWithValue(googleAuth ?? FakeGoogleAuth()),
  driveStoreProvider.overrideWithValue(driveStore ?? FakeDriveStore()),
  if (today != null) todayProvider.overrideWithValue(today),
];

/// App thật (router + locale vi) mở tại [initialLocation].
Future<Widget> testApp(
  String initialLocation, {
  YearOverrides? overrides,
  Box<String>? userEventsBox,
  Box<dynamic>? settingsBox,
  FileIo? fileIo,
  GoogleAuth? googleAuth,
  DriveStore? driveStore,
  DateTime? today,
}) async => ProviderScope(
  overrides: await testOverrides(
    overrides: overrides,
    userEventsBox: userEventsBox,
    settingsBox: settingsBox,
    fileIo: fileIo,
    googleAuth: googleAuth,
    driveStore: driveStore,
    today: today,
  ),
  child: KadeApp(router: createRouter(initialLocation: initialLocation)),
);
