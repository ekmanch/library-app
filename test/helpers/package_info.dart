import 'package:package_info_plus/package_info_plus.dart';

/// What About shows in tests, where there is no build to read.
void mockPackageInfo() => PackageInfo.setMockInitialValues(
  appName: 'Libri',
  packageName: 'library_app',
  version: '0.1.0',
  buildNumber: '1',
  buildSignature: '',
);
