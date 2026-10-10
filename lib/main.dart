import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/library_providers.dart';
import 'data/repository/fixture_library_repository.dart';
import 'features/settings/display_preferences.dart';
import 'features/shell/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(FixtureLibraryRepository()),
      ],
      child: const LibraryApp(),
    ),
  );
}

/// Rebuilds its themes whenever the display preferences change, so theme
/// and accent switches apply everywhere at once.
class LibraryApp extends ConsumerWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(displayPreferencesProvider);
    return MaterialApp(
      title: 'Library',
      theme: buildTheme(brightness: Brightness.light, accent: prefs.accent),
      darkTheme: buildTheme(brightness: Brightness.dark, accent: prefs.accent),
      themeMode: prefs.themeMode,
      home: const AppShell(),
    );
  }
}
