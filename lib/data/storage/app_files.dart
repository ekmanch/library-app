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
