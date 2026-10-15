import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// The folder for the files Libri keeps on the device: `library.json` and
/// `preferences.json`. It sits in the app documents directory, never the
/// cache, so the system does not clear it. The `libri` subfolder keeps the
/// Linux dev build, whose documents directory is `~/Documents`, tidy.
Future<Directory> appDataDirectory() async {
  final documents = await getApplicationDocumentsDirectory();
  return Directory('${documents.path}${Platform.pathSeparator}libri');
}

/// The folder for what Libri can fetch again: cover images, artist photos,
/// track lists, the IGDB token. It sits in the app cache directory, which
/// the system may clear, under the same `libri` subfolder.
Future<Directory> appCacheDirectory() async {
  final cache = await getApplicationCacheDirectory();
  return Directory('${cache.path}${Platform.pathSeparator}libri');
}
