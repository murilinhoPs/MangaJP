import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root: [ProviderScope] + [MaterialApp.router] (PRD §12.2).
class MangaJpApp extends StatelessWidget {
  const MangaJpApp({super.key, this.overrides = const []});

  /// Test-only Riverpod overrides (in-memory Drift, etc.).
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: const MangaJpMaterialApp(),
    );
  }
}

class MangaJpMaterialApp extends ConsumerWidget {
  const MangaJpMaterialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'MangaJP Study',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
