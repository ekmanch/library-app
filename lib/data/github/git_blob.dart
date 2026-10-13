import 'package:crypto/crypto.dart';

/// The sha git gives a blob with these bytes: the hex SHA-1 of
/// `"blob <length>\0"` followed by the bytes. It is what the Contents API
/// wants as the `sha` of the file being replaced, so the app computes it
/// from the raw download instead of asking for it.
String gitBlobSha(List<int> bytes) {
  final header = 'blob ${bytes.length}\u0000'.codeUnits;
  return sha1.convert([...header, ...bytes]).toString();
}
