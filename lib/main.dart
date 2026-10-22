import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/database/linux_app_support_migration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  maybeMigrateLinuxAppSupport();
  runApp(const MangaJpApp());
}
