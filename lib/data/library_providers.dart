import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../dev/demo_states.dart';
import '../dev/fake_github_api.dart';
import '../features/sync/sync_state.dart';
import 'github/github_api.dart';
import 'github/github_http_api.dart';
import 'models/library.dart';
import 'operations/library_operation.dart';
import 'repository/github_library_repository.dart';
import 'repository/library_repository.dart';
import 'repository/library_sync.dart';
import 'sync/sync_status.dart';

/// The folder for the files Libri keeps on the device. Overridden in
/// `main`; there is no default on purpose, so a missing override fails
/// loudly.
final appDataDirectoryProvider = Provider<Directory>(
  (ref) => throw UnimplementedError(
    'Override appDataDirectoryProvider in the root ProviderScope.',
  ),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

typedef GitHubApiFactory = GitHubApi Function({
  required String token,
  required String repository,
});

/// Builds the GitHub client for a token and a repo. The FIRST_RUN dev
/// switch gets the in-memory fake, so the flow can be walked without a
/// real token.
final gitHubApiFactoryProvider = Provider<GitHubApiFactory>((ref) {
  if (firstRunDemo) {
    return ({required token, required repository}) => FakeGitHubApi();
  }
  return ({required token, required repository}) => GitHubHttpApi(
    ref.watch(httpClientProvider),
    token: token,
    repository: repository,
  );
});

/// The repository for this run of the app: the library on GitHub, built
/// from the connection and the token, and rebuilt when either changes.
/// Tests override it with a fixture.
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final target = ref.watch(libraryConnectionProvider.select((c) => c.target));
  final token = ref.watch(tokenProvider);
  if (target == null || token == null) return const _Disconnected();
  final api = ref.watch(gitHubApiFactoryProvider)(
    token: token,
    repository: target.repository,
  );
  final repository = GitHubLibraryRepository(
    directory: ref.watch(appDataDirectoryProvider),
    api: api,
    path: target.file,
    branch: target.branch,
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// The library as it is now, updated after every applied operation.
/// Disposed when nothing shows it (after a disconnect), so a reconnect
/// starts clean.
final libraryProvider = StreamProvider.autoDispose<Library>(
  (ref) => ref.watch(libraryRepositoryProvider).watch(),
);

/// The sync side of the repository, or null when it has none.
final librarySyncProvider = Provider<LibrarySync?>((ref) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository is LibrarySync ? repository as LibrarySync : null;
});

/// The sync state for the banners (A12) and D6.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  final sync = ref.watch(librarySyncProvider);
  if (sync == null) {
    yield SyncStatus.idle;
    return;
  }
  yield sync.status;
  yield* sync.statusChanges;
});

/// Stands in while there is no connection. Nothing watches it then.
class _Disconnected implements LibraryRepository {
  const _Disconnected();

  static final _error = StateError('Not connected to a library');

  @override
  Future<Library> load() => Future.error(_error);

  @override
  Stream<Library> watch() => Stream.error(_error);

  @override
  Future<Library> apply(LibraryOperation operation) => Future.error(_error);
}
