import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/github/token_store.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/repository/local_library_repository.dart';
import 'package:library_app/data/storage/connection_store.dart';
import 'package:library_app/features/sync/sync_state.dart';

import '../../helpers/fake_library_sync.dart';

void main() {
  test('a library kept on the phone survives in connection.json', () {
    const kept = LibraryConnection(
      connected: false,
      keptLocally: true,
      repository: 'me/books',
      file: 'libri.json',
    );
    expect(kept.toJson()['local'], isTrue);
    final back = LibraryConnection.fromJson(kept.toJson());
    expect(back, kept);
    expect(back.showsLibrary, isTrue);
    expect(back.target, isNull);

    const connected = LibraryConnection(
      connected: true,
      repository: 'me/books',
    );
    expect(connected.toJson().containsKey('local'), isFalse);
    expect(LibraryConnection.fromJson(connected.toJson()), connected);
    expect(LibraryConnection.disconnected.showsLibrary, isFalse);
  });

  group('disconnect', () {
    late MemoryTokenStore tokens;
    late MemoryConnectionStore connections;
    late FakeLibrarySync sync;
    late ProviderContainer container;

    setUp(() {
      tokens = MemoryTokenStore()..token = 'github_pat_x';
      connections = MemoryConnectionStore()
        ..saved = const LibraryConnection(connected: true).toJson();
      sync = FakeLibrarySync();
      container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(tokens),
          connectionStoreProvider.overrideWithValue(connections),
          initialTokenProvider.overrideWithValue('github_pat_x'),
          librarySyncProvider.overrideWithValue(sync),
        ],
      );
      addTearDown(container.dispose);
    });

    test('keeping the library leaves the file and remembers that', () async {
      await container
          .read(libraryConnectionProvider.notifier)
          .disconnect(keepLibrary: true, sync: sync);
      final connection = container.read(libraryConnectionProvider);
      expect(connection.connected, isFalse);
      expect(connection.keptLocally, isTrue);
      expect(sync.keeps, 1);
      expect(sync.discards, 0);
      expect(tokens.token, isNull);
      expect(connections.saved?['local'], isTrue);
      expect(container.read(startOverProvider), isFalse);
    });

    test('deleting the library forgets everything and starts over', () async {
      await container
          .read(libraryConnectionProvider.notifier)
          .disconnect(keepLibrary: false, sync: sync);
      final connection = container.read(libraryConnectionProvider);
      expect(connection.connected, isFalse);
      expect(connection.keptLocally, isFalse);
      expect(sync.discards, 1);
      expect(sync.keeps, 0);
      expect(tokens.token, isNull);
      expect(connections.saved, isNull);
      expect(container.read(startOverProvider), isTrue);
    });
  });

  test('kept on the phone, the repository is the local file', () async {
    final dir = Directory.systemTemp.createTempSync('libri-local');
    addTearDown(() => dir.deleteSync(recursive: true));
    final container = ProviderContainer(
      overrides: [
        appDataDirectoryProvider.overrideWithValue(dir),
        initialConnectionProvider.overrideWithValue(
          const LibraryConnection(connected: false, keptLocally: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    final repository = container.read(libraryRepositoryProvider);
    expect(repository, isA<LocalLibraryRepository>());
    expect(container.read(librarySyncProvider), isNull);
    // No file left behind: an empty library rather than an error.
    final library = await repository.load();
    expect(library.entries, isEmpty);
  });
}
