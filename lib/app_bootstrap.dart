import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/database/linux_app_support_migration.dart';
import 'core/database/linux_data_directory_error_app.dart';

/// Root widget for `main`: migrates Linux app-support, or shows a PT-BR
/// error screen when HOME / XDG_DATA_HOME / getpwuid all fail.
///
/// [environment] and [passwdHome] are for tests (first resolution only).
Widget mangaJpBootstrapApp({
  Map<String, String>? environment,
  LinuxPasswdHomeLookup? passwdHome,
}) {
  final error = linuxAppSupportStartupError(
    environment: environment,
    passwdHome: passwdHome,
  );
  if (error is StateError) {
    return const LinuxDataDirectoryErrorApp();
  }
  return const MangaJpApp();
}
