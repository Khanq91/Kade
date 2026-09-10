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
import 'data/remote/remote_config.dart';
import 'data/remote/remote_config_provider.dart';
import 'data/settings_provider.dart';
import 'data/user_events_provider.dart';

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
    return MaterialApp.router(
      title: Strings.appName,
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      routerConfig: router ?? appRouter,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
