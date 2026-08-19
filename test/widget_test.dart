import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vlc_control/main.dart';
import 'package:vlc_control/src/settings/connection_settings.dart';

void main() {
  testWidgets('renders home page with transport controls', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const VlcRemoteApp(),
      ),
    );
    await tester.pump();

    expect(find.text('VLC Remote'), findsOneWidget);
    expect(find.byIcon(Icons.skip_next), findsOneWidget);
    expect(find.byIcon(Icons.skip_previous), findsOneWidget);

    // Dispose providers so the polling timers are cancelled before the
    // test framework checks for pending timers.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
