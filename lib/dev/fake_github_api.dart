import 'dart:convert';
import 'dart:typed_data';

import '../data/github/git_blob.dart';
import '../data/github/github_api.dart';
import '../data/library_codec.dart';

/// A GitHub repo in memory, for the widget tests, the repository tests
/// and the FIRST_RUN dev switch: files with blob shas and ETags, saves
/// that check the sha like the Contents API, and a commit list. Failures
/// can be injected with [failure] and [failNextPut].
class FakeGitHubApi implements GitHubApi {
  FakeGitHubApi({
    Map<String, String> files = const {},
    this.defaultBranch = 'main',
    this.canPush = true,
    this.latency = Duration.zero,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    files.forEach(setFile);
  }

  /// The repo the canvas draws in F6: the fixture as `library.json`,
  /// updated two days ago; a smaller copy in `backup/library-2025.json`
  /// from March; and `data/old-lists.json`, which is not a library.
  factory FakeGitHubApi.demo(
    String fixtureText, {
    Duration latency = Duration.zero,
    DateTime Function()? now,
  }) {
    final api = FakeGitHubApi(latency: latency, now: now);
    final today = api._now();
    final fixture = decodeLibrary(fixtureText);
    api.setFile(
      'library.json',
      fixtureText,
      message: 'Mark The Mummy as done',
      date: today.subtract(const Duration(days: 2)),
    );
    api.setFile(
      'backup/library-2025.json',
      encodeLibrary(
        fixture.copyWith(
          entries: fixture.entries.take(fixture.entries.length ~/ 2).toList(),
          plans: const [],
        ),
      ),
      message: 'Back up the library',
      date: DateTime(today.year, 3, 14),
    );
    api.setFile(
      'data/old-lists.json',
      '[1, 2]\n',
      message: 'Keep the old lists',
    );
    return api;
  }

  /// [FakeGitHubApi.demo] whose fixture is read on the first call: the
  /// FIRST_RUN dev switch, where the asset loads after the app starts.
  factory FakeGitHubApi.demoDeferred(
    Future<String> Function() loadFixture, {
    Duration latency = Duration.zero,
  }) {
    final api = FakeGitHubApi(latency: latency);
    api._loading = loadFixture().then((text) {
      final demo = FakeGitHubApi.demo(text, latency: latency);
      api._files.addAll(demo._files);
      api._commits.addAll(demo._commits);
      api._commitCount = demo._commitCount;
    });
    return api;
  }

  /// How long the FIRST_RUN dev switch's calls take, so the progress
  /// states show.
  static const demoLatency = Duration(milliseconds: 700);

  Future<void>? _loading;

  final String defaultBranch;
  bool canPush;

  /// How long every call takes, so the dev flow shows its progress.
  Duration latency;
  final DateTime Function() _now;
  final Map<String, Uint8List> _files = {};
  final Map<String, List<CommitInfo>> _commits = {};
  int _commitCount = 0;

  /// When set, every call fails with it.
  GitHubFailure? failure;

  /// The next save fails with this, without saving.
  GitHubFailure? failNextPut;

  /// The next save saves, then fails with this: a lost answer.
  GitHubFailure? loseNextPutResponse;

  /// Every call, for assertions: `GET path`, `GET path etag`, `PUT path`.
  final List<String> requests = [];

  int get putCount => requests.where((r) => r.startsWith('PUT')).length;

  /// The file's text, or null.
  String? text(String path) {
    final bytes = _files[path];
    return bytes == null ? null : utf8.decode(bytes);
  }

  /// Sets a file as if someone else pushed it, with a commit.
  void setFile(String path, String text, {String? message, DateTime? date}) {
    _files[path] = Uint8List.fromList(utf8.encode(text));
    _record(path, message ?? 'Edit $path', date: date);
  }

  void _record(String path, String message, {DateTime? date}) {
    _commitCount++;
    _commits
        .putIfAbsent(path, () => [])
        .insert(
          0,
          CommitInfo(
            sha: 'commit-$_commitCount',
            message: message,
            date: date ?? _now(),
          ),
        );
  }

  Future<void> _call(String request) async {
    requests.add(request);
    await _loading;
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failure case final failure?) throw GitHubException(failure);
  }

  static String _etag(List<int> bytes) => '"${gitBlobSha(bytes)}"';

  @override
  Future<RepoInfo> getRepo() async {
    await _call('GET repo');
    return RepoInfo(defaultBranch: defaultBranch, canPush: canPush);
  }

  @override
  Future<RawFile?> getFileRaw(
    String path, {
    required String branch,
    String? etag,
  }) async {
    await _call('GET $path${etag == null ? '' : ' $etag'}');
    final bytes = _files[path];
    if (bytes == null) {
      throw const GitHubException(GitHubFailure.notFound, status: 404);
    }
    if (etag != null && etag == _etag(bytes)) return null;
    return RawFile(Uint8List.fromList(bytes), etag: _etag(bytes));
  }

  @override
  Future<PutResult> putFile(
    String path, {
    required String branch,
    required List<int> bytes,
    required String message,
    String? sha,
  }) async {
    await _call('PUT $path');
    if (failNextPut case final failure?) {
      failNextPut = null;
      throw GitHubException(failure);
    }
    final current = _files[path];
    if (current == null ? sha != null : sha != gitBlobSha(current)) {
      throw const GitHubException(GitHubFailure.conflict, status: 422);
    }
    _files[path] = Uint8List.fromList(bytes);
    _record(path, message);
    if (loseNextPutResponse case final failure?) {
      loseNextPutResponse = null;
      throw GitHubException(failure);
    }
    return PutResult(
      blobSha: gitBlobSha(bytes),
      commitSha: _commits[path]!.first.sha,
    );
  }

  @override
  Future<List<TreeFile>> listFiles({
    required String branch,
    String suffix = '.json',
  }) async {
    await _call('GET tree');
    return [
      for (final MapEntry(key: path, value: bytes) in _files.entries)
        if (path.endsWith(suffix))
          TreeFile(path: path, size: bytes.length, sha: gitBlobSha(bytes)),
    ];
  }

  @override
  Future<List<CommitInfo>> commits(
    String path, {
    required String branch,
    int limit = 5,
  }) async {
    await _call('GET commits $path');
    return (_commits[path] ?? const []).take(limit).toList();
  }
}
