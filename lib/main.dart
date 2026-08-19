import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/settings/connection_settings.dart';
import 'src/ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const VlcRemoteApp(),
    ),
  );
}

class VlcRemoteApp extends StatelessWidget {
  const VlcRemoteApp({super.key});

  static const _seed = Color(0xFFFF8800); // VLC orange

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VLC Remote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}
