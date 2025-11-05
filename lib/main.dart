import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mini_music_test_app/core/di/providers.dart';
import 'package:mini_music_test_app/presentation/pages/catalog_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final downloadBox = await Hive.openBox('downloads');
  final queueBox = await Hive.openBox('queue');
  runApp(
    ProviderScope(
      overrides: [
        downloadBoxProvider.overrideWithValue(downloadBox),
        queueBoxProvider.overrideWithValue(queueBox),
      ],
      child: const MiniMusicApp(),
    ),
  );
}

class MiniMusicApp extends ConsumerWidget {
  const MiniMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Mini Music Player',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      home: const CatalogPage(),
    );
  }
}
