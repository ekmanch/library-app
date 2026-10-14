import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/github/github_api.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/data/operations/operations.dart';
import 'package:library_app/data/repository/github_library_repository.dart';
import 'package:library_app/data/sync/sync_status.dart';
import 'package:library_app/dev/fake_github_api.dart';

import '../../helpers/sample_library.dart';

void main() {
  late Directory dir;
  late FakeGitHubApi github;
  final seedText = encodeLibrary(sampleLibrary());
  const debounce = Duration(milliseconds: 20);
  final logged = <String>[];

  setUp(() {
    dir = Directory.systemTemp.createTempSync('libri-github-');
    github = FakeGitHubApi(files: {'library.json': seedText});
    logged.clear();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  GitHubLibraryRepository repository() => GitHubLibraryRepository(
    directory: dir,
    api: github,
    path: 'library.json',
    branch: 'main',
    debounce: debounce,
    log: logged.add,
  );

  /// Lets the debounce fire and every sync finish.
  Future<void> settle(GitHubLibraryRepository repo) async {
    await Future<void>.delayed(debounce * 2);
    await repo.flush();
  }

  String pendingFile() => File('${dir.path}/pending.json').readAsStringSync();

  test('a new install downloads the file and checks once', () async {
    final repo = repository();
    expect(await repo.load(), sampleLibrary());
    await repo.flush();
    expect(File('${dir.path}/library.json').readAsStringSync(), seedText);
    expect(File('${dir.path}/sync.json').existsSync(), isTrue);
    expect(github.requests, [
      'GET library.json',
      startsWith('GET library.json "'), // Conditional: answered 304.
    ]);
    expect(repo.status.phase, SyncPhase.idle);
    expect(repo.status.lastSynced, isNotNull);
    expect(repo.status.pendingCount, 0);
    repo.dispose();
  });

  test('watching alone loads the queue and checks, like the UI', () async {
    final repo = repository();
    final emitted = <Object>[];
    final sub = repo.watch().listen(emitted.add);
    await pumpEventQueue();
    await repo.flush();
    await sub.cancel();
    expect(emitted, [sampleLibrary()]);
    expect(github.requests, hasLength(2));
    expect(repo.status.lastChecked, isNotNull);
    repo.dispose();
  });

  test('a restart shows the cache and only checks', () async {
    final first = repository();
    await first.load();
    await first.flush();
    first.dispose();
    github.requests.clear();

    final second = repository();
    expect(await second.load(), sampleLibrary());
    await second.flush();
    expect(github.requests, [startsWith('GET library.json "')]);
    second.dispose();
  });

  test('edits made within the debounce go out as one commit', () async {
    final repo = repository();
    await repo.load();
    await repo.flush();
    final statuses = <SyncPhase>[];
    final sub = repo.statusChanges.listen((s) => statuses.add(s.phase));

    await repo.apply(SetStatus(mummy.id, EntryStatus.want));
    await repo.apply(SetRating(mummy.id, 3));
    await repo.apply(SetPlanStarted(halloweenPlan.id, true));
    expect(repo.status.pendingCount, 3);
    expect(github.putCount, 0, reason: 'nothing goes out before the pause');
    await settle(repo);
    await sub.cancel();

    expect(github.putCount, 1);
    final library = await repo.load();
    expect(github.text('library.json'), encodeLibrary(library));
    expect(
      github.commits('library.json', branch: 'main'),
      completion([
        isA<CommitInfo>().having(
          (c) => c.message,
          'message',
          'Mark The Mummy as want and 2 other changes\n\n'
              '- Mark The Mummy as want\n'
              '- Rate The Mummy 3 of 10\n'
              '- Start Halloween 2026',
        ),
        isA<CommitInfo>(),
      ]),
    );
    expect(repo.status.pendingCount, 0);
    expect(repo.status.phase, SyncPhase.idle);
    expect(statuses, contains(SyncPhase.saving));
    expect(pendingFile(), contains('"operations": []'));
    repo.dispose();
  });

  test('one edit is committed with its summary', () async {
    final repo = repository();
    await repo.load();
    await repo.apply(SetStatus(mummy.id, EntryStatus.want));
    await settle(repo);
    final commits = await github.commits('library.json', branch: 'main');
    expect(commits.first.message, 'Mark The Mummy as want');
    repo.dispose();
  });

  test('a file changed on GitHub is taken, with the edits on top', () async {
    final repo = repository();
    await repo.load();
    await repo.flush();
    final emitted = <Object>[];
    final sub = repo.watch().skip(1).listen(emitted.add);
    await pumpEventQueue();

    // Someone rates Dirt on another device.
    github.setFile(
      'library.json',
      encodeLibrary(
        sampleLibrary().copyWith(entries: [mummy, dirt.copyWith(rating: 5)]),
      ),
    );
    await repo.apply(SetStatus(mummy.id, EntryStatus.want));
    await settle(repo);
    await sub.cancel();

    final saved = decodeLibrary(github.text('library.json')!);
    expect(saved.entryById(dirt.id)!.rating, 5);
    expect(saved.entryById(mummy.id)!.status, EntryStatus.want);
    expect(await repo.load(), saved);
    expect(emitted.last, saved);
    expect(github.putCount, 1);
    repo.dispose();
  });

  test('a conflict refetches, re-applies and saves again', () async {
    final repo = repository();
    await repo.load();
    await repo.flush();
    await repo.apply(SetStatus(mummy.id, EntryStatus.want));
    // The file changes between the check and the save.
    github.failNextPut = GitHubFailure.conflict;
    github.setFile(
      'library.json',
      encodeLibrary(
        sampleLibrary().copyWith(entries: [mummy, dirt.copyWith(rating: 5)]),
      ),
    );
    await settle(repo);
    expect(github.putCount, 2);
    final saved = decodeLibrary(github.text('library.json')!);
    expect(saved.entryById(dirt.id)!.rating, 5);
    expect(saved.entryById(mummy.id)!.status, EntryStatus.want);
    expect(repo.status.phase, SyncPhase.idle);
    expect(repo.status.pendingCount, 0);
    repo.dispose();
  });

  test('offline edits wait in the queue and go out after a restart', () async {
    final repo = repository();
    await repo.load();
    await repo.flush();
    github.failure = GitHubFailure.offline;
    await repo.apply(SetStatus(mummy.id, EntryStatus.want));
    await settle(repo);
    expect(repo.status.phase, SyncPhase.offline);
    expect(repo.status.pendingCount, 1);
    expect(github.putCount, 0);
    expect(pendingFile(), contains('"op": "setStatus"'));
    repo.dispose();

    github.failure = null;
    final again = repository();
    expect(
      (await again.load()).entryById(mummy.id)!.status,
      EntryStatus.want,
      reason: 'the cache has the edit',
    );
    await again.syncNow();
    expect(github.putCount, 1);
    expect(
      decodeLibrary(github.text('library.json')!).entryById(mummy.id)!.status,
      EntryStatus.want,
    );
    expect(again.status.phase, SyncPhase.idle);
    expect(again.status.pendingCount, 0);
    again.dispose();
  });

  test('a refused token is a token problem and keeps the queue', () async {
    final repo = repository();
    await repo.load();
    await repo.flush();
    github.failure = GitHubFailure.unauthorized;
    await repo.apply(SetStatus(mummy.id, EntryStatus.want));
    await settle(repo);
    expect(repo.status.phase, SyncPhase.tokenProblem);
    expect(repo.status.pendingCount, 1);
    repo.dispose();
  });

  test('a rate limit is a failure that Retry sends again', () async {
    final repo = repository();
    await repo.load();
    await repo.flush();
    github.failure = GitHubFailure.rateLimited;
    await repo.apply(SetStatus(mummy.id, EntryStatus.want));
    await settle(repo);
    expect(repo.status.phase, SyncPhase.failed);
    github.failure = null;
    await repo.syncNow();
    expect(repo.status.phase, SyncPhase.idle);
    expect(github.putCount, 1);
    repo.dispose();
  });

  group('a save whose answer was lost', () {
    test('that landed is not sent twice', () async {
      final repo = repository();
      await repo.load();
      await repo.flush();
      github.loseNextPutResponse = GitHubFailure.offline;
      await repo.apply(SetStatus(mummy.id, EntryStatus.want));
      await settle(repo);
      expect(repo.status.phase, SyncPhase.offline);
      expect(pendingFile(), contains('"inFlight": {'));
      repo.dispose();

      final again = repository();
      await again.load();
      await again.syncNow();
      expect(github.putCount, 1);
      expect(again.status.phase, SyncPhase.idle);
      expect(again.status.pendingCount, 0);
      expect(logged, contains(contains('landed')));
      again.dispose();
    });

    test('that did not land is sent again', () async {
      final repo = repository();
      await repo.load();
      await repo.flush();
      github.failNextPut = GitHubFailure.offline;
      await repo.apply(SetStatus(mummy.id, EntryStatus.want));
      await settle(repo);
      repo.dispose();

      final again = repository();
      await again.load();
      await again.syncNow();
      expect(github.putCount, 2);
      expect(
        decodeLibrary(github.text('library.json')!).entryById(mummy.id)!.status,
        EntryStatus.want,
      );
      expect(again.status.pendingCount, 0);
      again.dispose();
    });

    test('that landed under a later change is found in the commits', () async {
      final repo = repository();
      await repo.load();
      await repo.flush();
      github.loseNextPutResponse = GitHubFailure.offline;
      await repo.apply(SetStatus(mummy.id, EntryStatus.want));
      await settle(repo);
      repo.dispose();
      // Then another device rates Dirt.
      final later = decodeLibrary(github.text('library.json')!);
      github.setFile(
        'library.json',
        encodeLibrary(
          later.copyWith(
            entries: [later.entries.first, dirt.copyWith(rating: 5)],
          ),
        ),
      );

      final again = repository();
      await again.load();
      await again.syncNow();
      expect(github.putCount, 1);
      expect(again.status.pendingCount, 0);
      final library = await again.load();
      expect(library.entryById(mummy.id)!.status, EntryStatus.want);
      expect(library.entryById(dirt.id)!.rating, 5);
      again.dispose();
    });
  });

  test('an operation that changes nothing is not queued', () async {
    final repo = repository();
    await repo.load();
    await repo.flush();
    await repo.apply(const DeleteEntry('movies/missing'));
    await settle(repo);
    expect(repo.status.pendingCount, 0);
    expect(github.putCount, 0);
    expect(File('${dir.path}/pending.json').existsSync(), isFalse);
    repo.dispose();
  });

  test('an operation that is not allowed throws and is not queued', () async {
    final repo = repository();
    await repo.load();
    await repo.flush();
    await expectLater(
      () => repo.apply(SetStatus(mummy.id, EntryStatus.inProgress)),
      throwsArgumentError,
    );
    expect(repo.status.pendingCount, 0);
    repo.dispose();
  });

  test(
    'a cache that differs with nothing pending is replaced, never saved',
    () async {
      final repo = repository();
      await repo.load();
      await repo.flush();
      repo.dispose();
      // A bug, or an older app, left something in the cache.
      File('${dir.path}/library.json').writeAsStringSync(
        encodeLibrary(sampleLibrary().copyWith(entries: [mummy])),
      );

      final again = repository();
      expect((await again.load()).entries, hasLength(1));
      await again.flush();
      expect(await again.load(), sampleLibrary());
      expect(github.putCount, 0);
      expect(logged, contains(contains('GitHub\'s copy')));
      again.dispose();
    },
  );

  test('discard removes the cache, the queue and the meta', () async {
    final repo = repository();
    await repo.load();
    github.failure = GitHubFailure.offline;
    await repo.apply(SetStatus(mummy.id, EntryStatus.want));
    await repo.discard();
    await Future<void>.delayed(debounce * 2);
    expect(dir.listSync(), isEmpty);
    expect(github.putCount, 0);
    repo.dispose();
  });

  test('discard keeping the library leaves only library.json', () async {
    final repo = repository();
    await repo.load();
    github.failure = GitHubFailure.offline;
    await repo.apply(SetStatus(mummy.id, EntryStatus.want));
    await repo.discard(keepLibrary: true);
    await Future<void>.delayed(debounce * 2);
    expect(dir.listSync().map((f) => f.uri.pathSegments.last), [
      'library.json',
    ]);
    expect(github.putCount, 0);
    repo.dispose();
  });

  test(
    'the queue survives without a sync meta, costing one download',
    () async {
      final repo = repository();
      await repo.load();
      await repo.flush();
      repo.dispose();
      File('${dir.path}/sync.json').deleteSync();
      github.requests.clear();

      final again = repository();
      await again.load();
      await again.apply(SetStatus(mummy.id, EntryStatus.want));
      await settle(again);
      expect(github.requests.first, 'GET library.json');
      expect(github.putCount, 1);
      expect(again.status.pendingCount, 0);
      again.dispose();
    },
  );

  test(
    'pending.json keeps the queue even when the first load is offline',
    () async {
      github.failure = GitHubFailure.offline;
      final repo = repository();
      await expectLater(repo.load(), throwsA(isA<GitHubException>()));
      expect(repo.status.phase, SyncPhase.offline);
      repo.dispose();
    },
  );
}
