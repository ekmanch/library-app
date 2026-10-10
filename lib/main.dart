import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/library_codec.dart';
import 'data/library_providers.dart';
import 'data/repository/fixture_library_repository.dart';
import 'dev/long_lists.dart';
import 'features/settings/display_preferences.dart';
import 'features/shell/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(
          FixtureLibraryRepository(
            loadJson: longListsEnabled ? _loadPaddedFixture : null,
          ),
        ),
      ],
      child: const LibraryApp(),
    ),
  );
}

/// The fixture with generated entries added, for trying long lists.
Future<String> _loadPaddedFixture() async {
  final json = await rootBundle.loadString(FixtureLibraryRepository.assetPath);
  return encodeLibrary(padForLongLists(decodeLibrary(json)));
}

/// Rebuilds its themes whenever the display preferences change, so theme
/// and accent switches apply everywhere at once.
class LibraryApp extends ConsumerWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(displayPreferencesProvider);
    return MaterialApp(
      title: 'Libri',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(brightness: Brightness.light, accent: prefs.accent),
      darkTheme: buildTheme(brightness: Brightness.dark, accent: prefs.accent),
      themeMode: prefs.themeMode,
      home: const AppShell(),
    );
  }
}
