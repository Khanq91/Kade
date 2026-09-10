import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'core/strings.dart';
import 'data/local/hive_boxes.dart';
import 'data/local/user_event_repository.dart';
import 'data/reminder_scheduler.dart';
import 'data/remote/remote_config.dart';
import 'data/remote/remote_config_provider.dart';
import 'data/settings_provider.dart';
import 'data/sync/google_auth.dart';
import 'data/sync/sync_trigger.dart';
import 'data/user_events_provider.dart';
import 'platform/file_io.dart';
import 'platform/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.logMissing();
  await HiveBoxes.open();
  final remoteConfig = RemoteConfigRepository(
    box: Hive.box<String>(HiveBoxes.remoteConfig),
    loadAsset: rootBundle.loadString,
    url: Env.configUrl,
  );
  final userEvents = UserEventRepository(
    Hive.box<String>(HiveBoxes.userEvents),
  );
  runApp(
    ProviderScope(
      overrides: [
        remoteConfigRepositoryProvider.overrideWithValue(remoteConfig),
        userEventRepositoryProvider.overrideWithValue(userEvents),
        settingsBoxProvider.overrideWithValue(
          Hive.box<dynamic>(HiveBoxes.settings),
        ),
        fileIoProvider.overrideWithValue(FilePickerFileIo()),
        googleAuthProvider.overrideWithValue(GoogleSignInAuth()),
        // Web không nhắc (plan §4.6).
        notificationsProvider.overrideWithValue(
          kIsWeb ? const NoopNotifications() : LocalNotifications(),
        ),
      ],
      child: const KadeApp(),
    ),
  );
}

/// Gốc app: MaterialApp.router với go_router (core/router.dart), locale vi.
class KadeApp extends StatelessWidget {
  const KadeApp({super.key, this.router});

  /// Router thay thế (test mở thẳng một route); mặc định [appRouter].
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    final r = router ?? appRouter;
    return AppLifecycle(
      router: r,
      child: MaterialApp.router(
        title: Strings.appName,
        theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
        routerConfig: r,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}

/// Nối vòng đời app với [SyncTrigger] (bước 13) và [ReminderScheduler] (bước
/// 16): tạo lúc start (từ đó tự nghe đăng nhập + sự kiện), báo pause/resume;
/// chạm thông báo → [router] mở route trong payload.
class AppLifecycle extends ConsumerStatefulWidget {
  const AppLifecycle({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<AppLifecycle> createState() => _AppLifecycleState();
}

class _AppLifecycleState extends ConsumerState<AppLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(syncTriggerProvider);
    ref.read(reminderSchedulerProvider).start(widget.router.go);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final trigger = ref.read(syncTriggerProvider);
    if (state == AppLifecycleState.resumed) {
      trigger.onResume();
      ref.read(reminderSchedulerProvider).reschedule();
    } else {
      trigger.onPause();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
