import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_info.dart';
import 'data/github/token_store.dart';
import 'data/library_codec.dart';
import 'data/library_providers.dart';
import 'data/preferences/preferences_store.dart';
import 'data/repository/fixture_library_repository.dart';
import 'data/storage/app_files.dart';
import 'data/storage/connection_store.dart';
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

/// The app with its storage in [directory]: the cached `library.json`,
/// `pending.json`, `sync.json`, `connection.json` and `preferences.json`.
/// The integration tests pass a temporary folder, a memory [tokenStore]
/// and a fake [api].
Future<Widget> bootstrap(
  Directory directory, {
  TokenStore? tokenStore,
  GitHubApiFactory? api,
}) async {
  File file(String name) =>
      File('${directory.path}${Platform.pathSeparator}$name');
  final preferences = FilePreferencesStore(file('preferences.json'));
  final prefs = DisplayPreferences.fromJson(await preferences.load());
  final tokens = tokenStore ?? SecureTokenStore();
  final connections = FileConnectionStore(file('connection.json'));

  String? token;
  try {
    token = await tokens.read();
  } on Object catch (e) {
    // Unreadable secure storage: ask for the token again (first run).
    debugPrint('Could not read the token: $e');
  }
  final stored = await connections.load();
  var connection = stored == null
      ? LibraryConnection.disconnected
      : LibraryConnection.fromJson(stored);
  if (token == null) connection = connection.copyWith(connected: false);
  // The generated entries are for looking only: in memory, no GitHub, and
  // no first run.
  if (longListsEnabled) connection = const LibraryConnection(connected: true);

  return ProviderScope(
    overrides: [
      appDataDirectoryProvider.overrideWithValue(directory),
      tokenStoreProvider.overrideWithValue(tokens),
      connectionStoreProvider.overrideWithValue(connections),
      initialTokenProvider.overrideWithValue(token),
      initialConnectionProvider.overrideWithValue(connection),
      preferencesStoreProvider.overrideWithValue(preferences),
      initialDisplayPreferencesProvider.overrideWithValue(prefs),
      if (api != null) gitHubApiFactoryProvider.overrideWithValue(api),
      if (longListsEnabled)
        libraryRepositoryProvider.overrideWithValue(
          FixtureLibraryRepository(loadJson: _loadPaddedFixture),
        ),
    ],
    child: const LibraryApp(),
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
