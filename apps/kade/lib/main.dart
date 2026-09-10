import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import 'core/env.dart';
import 'core/strings.dart';
import 'data/local/hive_boxes.dart';
import 'data/remote/remote_config.dart';
import 'data/remote/remote_config_provider.dart';
import 'features/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.logMissing();
  await HiveBoxes.open();
  final remoteConfig = RemoteConfigRepository(
    box: Hive.box<String>(HiveBoxes.remoteConfig),
    loadAsset: rootBundle.loadString,
    url: Env.configUrl,
  );
  runApp(
    ProviderScope(
      overrides: [
        remoteConfigRepositoryProvider.overrideWithValue(remoteConfig),
      ],
      child: const KadeApp(),
    ),
  );
}

/// Gốc app. Bước 5: home tạm là Settings; MonthView thay ở bước 6.
class KadeApp extends StatelessWidget {
  const KadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appName,
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const SettingsScreen(),
    );
  }
}
