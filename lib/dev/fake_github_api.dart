import 'dart:convert';
import 'dart:typed_data';

import '../data/github/git_blob.dart';
import '../data/github/github_api.dart';

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

  final String defaultBranch;
  bool canPush;

  /// How long every call takes, so the dev flow shows its progress.
  final Duration latency;
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
  void setFile(String path, String text, {String? message}) {
    _files[path] = Uint8List.fromList(utf8.encode(text));
    _record(path, message ?? 'Edit $path');
  }

  void _record(String path, String message) {
    _commitCount++;
    _commits
        .putIfAbsent(path, () => [])
        .insert(
          0,
          CommitInfo(
            sha: 'commit-$_commitCount',
            message: message,
            date: _now(),
          ),
        );
  }

  Future<void> _call(String request) async {
    requests.add(request);
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
