import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the GitHub token lives. It never goes into a plain file or into
/// `library.json`.
abstract interface class TokenStore {
  /// The stored token, or null when there is none. May throw when the
  /// secure storage cannot be read; the app then treats itself as
  /// disconnected and asks for the token again.
  Future<String?> read();

  Future<void> write(String token);

  Future<void> delete();
}

/// Keeps the token in memory only: tests, the screenshots and the dev
/// switches.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> delete() async => token = null;
}

/// The phone's secure storage: the Android Keystore, libsecret on the
/// Linux dev build.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'github_token';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}
