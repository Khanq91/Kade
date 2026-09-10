// Helper chung cho widget test: remote config giả (không HTTP), box sự kiện
// in-memory (không IO → không cần `tester.runAsync`, tránh E009), FileIo giả,
// GoogleAuth giả + app thật với router; `testTall` cho màn dài (E009).
import 'dart:async';
import 'dart:io';

import 'package:calendar_data/calendar_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kade/core/router.dart';
import 'package:kade/data/local/user_event_repository.dart';
import 'package:kade/data/reminders.dart';
import 'package:kade/data/remote/remote_config.dart';
import 'package:kade/data/remote/remote_config_provider.dart';
import 'package:kade/data/settings_provider.dart';
import 'package:kade/data/sync/drive_store.dart';
import 'package:kade/data/sync/google_auth.dart';
import 'package:kade/data/sync/sync_trigger.dart';
import 'package:kade/data/upcoming_provider.dart';
import 'package:kade/data/user_events_provider.dart';
import 'package:kade/main.dart';
import 'package:kade/platform/file_io.dart';
import 'package:kade/platform/notifications.dart';

/// GoogleAuth giả. Android-like mặc định (`supportsAuthenticate` true):
/// [signIn] trả [signInUser] hoặc throw [signInError]. Web-like
/// (`supportsAuthenticate: false`): test gọi [emitSignIn] thay nút GIS.
/// [accessToken]: có [silentToken] → trả luôn; đã cấp tương tác trước đó →
/// trả lại token đó (như cache thật); không thì chỉ khi interactive (đếm
/// [interactiveCalls]) hoặc throw [authorizeError]. [clearToken] ghi vào
/// [clearedTokens], bỏ token đó; sau đó im lặng trả [tokenAfterClear] (giả
/// Android tự làm mới) hoặc null (web: phải hỏi lại).
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
  String? tokenAfterClear;
  int interactiveCalls = 0;
  final clearedTokens = <String>[];
  String? _granted;

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
    _granted = null;
    _events.add(null);
  }

  @override
  Future<String?> accessToken({bool interactive = false}) async {
    if (current == null) return null;
    if (silentToken != null) return silentToken;
    if (_granted != null) return _granted;
    if (!interactive) return null;
    final e = authorizeError;
    if (e != null) throw e;
    interactiveCalls++;
    return _granted = 'tok-$interactiveCalls';
  }

  @override
  Future<void> clearToken(String token) async {
    clearedTokens.add(token);
    if (silentToken == token) silentToken = tokenAfterClear;
    if (_granted == token) _granted = null;
  }
}

/// Notifications giả (bước 16): ghi lần đặt gần nhất vào [scheduled], đếm
/// [scheduleCalls] / [permissionRequests], trả [permissionGranted]; [tap]
/// giả user chạm thông báo có payload.
class FakeNotifications implements Notifications {
  void Function(String payload)? _onSelect;
  bool initialized = false;
  List<Reminder> scheduled = const [];
  int scheduleCalls = 0;
  int permissionRequests = 0;
  bool permissionGranted = true;

  @override
  Future<void> init(void Function(String payload) onSelect) async {
    initialized = true;
    _onSelect = onSelect;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> schedule(List<Reminder> reminders) async {
    scheduleCalls++;
    scheduled = reminders;
  }

  void tap(String payload) => _onSelect?.call(payload);
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
/// [error] → ném ở mọi lệnh; token trong [badTokens] → 401 (token hết hạn).
class FakeDriveStore implements DriveStore {
  RemoteFile? file;
  DriveException? error;
  final badTokens = <String>{};
  final calls = <String>[];
  final tokens = <String>[];

  void _check(String token, String op) {
    tokens.add(token);
    calls.add(op);
    final e = error;
    if (e != null) throw e;
    if (badTokens.contains(token)) {
      throw DriveException(401, 'Invalid Credentials');
    }
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

  @override
  Future<void> delete(String token, String id) async {
    _check(token, 'delete');
    file = null;
  }
}

/// testWidgets với viewport 800×1600 để form/DayDetail/Settings không bị
/// offstage (E009).
void testTall(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    setViewport(tester, const Size(800, 1600));
    await callback(tester);
  });
}

/// Đặt kích thước cửa sổ (logical px, DPR 1) cho test responsive; tự reset.
void setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
/// mới), [today] cho "Sắp tới" và [clock] cho trigger sync nếu truyền.
Future<List<Override>> testOverrides({
  YearOverrides? overrides,
  Box<String>? userEventsBox,
  Box<dynamic>? settingsBox,
  FileIo? fileIo,
  GoogleAuth? googleAuth,
  DriveStore? driveStore,
  DateTime? today,
  DateTime Function()? clock,
  bool? isWeb,
  Notifications? notifications,
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
  if (clock != null) clockProvider.overrideWithValue(clock),
  if (isWeb != null) platformIsWebProvider.overrideWithValue(isWeb),
  notificationsProvider.overrideWithValue(notifications ?? FakeNotifications()),
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
  DateTime Function()? clock,
  bool? isWeb,
  Notifications? notifications,
}) async => ProviderScope(
  overrides: await testOverrides(
    overrides: overrides,
    userEventsBox: userEventsBox,
    settingsBox: settingsBox,
    fileIo: fileIo,
    googleAuth: googleAuth,
    driveStore: driveStore,
    today: today,
    clock: clock,
    isWeb: isWeb,
    notifications: notifications,
  ),
  child: KadeApp(router: createRouter(initialLocation: initialLocation)),
);

/// Giả lập nền tảng báo đổi trạng thái vòng đời (paused/resumed…) qua kênh
/// `flutter/lifecycle` — như Flutter thật, không gọi API @protected.
Future<void> sendLifecycle(WidgetTester tester, AppLifecycleState state) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      const StringCodec().encodeMessage('$state'),
      (_) {},
    );
