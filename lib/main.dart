import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_info.dart';
import 'data/library_codec.dart';
import 'data/library_providers.dart';
import 'data/preferences/preferences_store.dart';
import 'data/repository/fixture_library_repository.dart';
import 'data/repository/library_repository.dart';
import 'data/repository/local_library_repository.dart';
import 'data/storage/app_files.dart';
import 'dev/long_lists.dart';
import 'features/first_run/first_run_flow.dart';
import 'features/settings/display_preferences.dart';
import 'features/shell/app_shell.dart';
import 'features/sync/sync_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await bootstrap(await appDataDirectory()));
}

/// The app with its storage in [directory]: `library.json` and
/// `preferences.json`. The integration tests pass a temporary folder.
Future<Widget> bootstrap(Directory directory) async {
  final store = FilePreferencesStore(
    File('${directory.path}${Platform.pathSeparator}preferences.json'),
  );
  final prefs = DisplayPreferences.fromJson(await store.load());
  return ProviderScope(
    overrides: [
      libraryRepositoryProvider.overrideWithValue(_repository(directory)),
      preferencesStoreProvider.overrideWithValue(store),
      initialDisplayPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const LibraryApp(),
  );
}

LibraryRepository _repository(Directory directory) {
  // The generated entries are for looking only and never reach the file.
  if (longListsEnabled) {
    return FixtureLibraryRepository(loadJson: _loadPaddedFixture);
  }
  return LocalLibraryRepository(
    File('${directory.path}${Platform.pathSeparator}library.json'),
    // Until the GitHub connection exists (phase 4), a new install starts
    // from the bundled fixture.
    seed: () => rootBundle.loadString(FixtureLibraryRepository.assetPath),
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
    final connected = ref.watch(
      libraryConnectionProvider.select((c) => c.connected),
    );
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(brightness: Brightness.light, accent: prefs.accent),
      darkTheme: buildTheme(brightness: Brightness.dark, accent: prefs.accent),
      themeMode: prefs.themeMode,
      // Until a library file is connected the app is the first run (F1 to
      // F7); Disconnect in D6 brings it back.
      home: connected ? const AppShell() : const FirstRunFlow(),
    );
  }
}
