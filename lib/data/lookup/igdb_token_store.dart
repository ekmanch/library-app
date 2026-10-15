import '../storage/json_file.dart';

/// The IGDB app access token from Twitch, kept on the device between runs.
/// Twitch issues them for about two months; one is reused until a day
/// before it expires, or until IGDB refuses it.
class IgdbTokenStore {
  IgdbTokenStore(this.file, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final JsonFile file;
  final DateTime Function() _now;

  /// How long before the expiry a token stops being used.
  static const margin = Duration(days: 1);

  /// The stored token while it is good for at least [margin] more.
  Future<String?> valid() async {
    final json = await file.read();
    final token = json?['access_token'];
    final expires = json?['expires_at'];
    if (token is! String || token.isEmpty || expires is! String) return null;
    final expiresAt = DateTime.tryParse(expires);
    if (expiresAt == null) return null;
    return _now().add(margin).isBefore(expiresAt) ? token : null;
  }

  Future<void> save(String token, {required Duration expiresIn}) => file.write({
    'access_token': token,
    'expires_at': _now().add(expiresIn).toUtc().toIso8601String(),
  });

  Future<void> clear() => file.delete();
}
