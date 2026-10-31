import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Keys for the Linux data-directory error screen (HOME / getpwuid failed).
abstract final class LinuxDataDirectoryErrorKeys {
  static const screen = Key('linux-data-dir-error');
  static const title = Key('linux-data-dir-error-title');
  static const body = Key('linux-data-dir-error-body');
  static const command = Key('linux-data-dir-error-command');
}

/// Copy shown when the Linux data folder cannot be resolved.
abstract final class LinuxDataDirectoryErrorCopy {
  static const title = 'Não foi possível abrir a pasta de dados';

  static const body =
      'O MangaJP não achou a pasta de dados porque a variável HOME '
      'não está definida.\n\n'
      'Defina HOME e abra o app de novo, por exemplo:';

  static const command = 'HOME=/home/<usuário> manga_jp';
}

/// Full-screen error instead of the main app when Linux cannot resolve
/// the data directory. PT-BR, no database open, no crash/blank window.
class LinuxDataDirectoryErrorApp extends StatelessWidget {
  const LinuxDataDirectoryErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MangaJP Study',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      home: const LinuxDataDirectoryErrorPage(),
    );
  }
}

/// Body of [LinuxDataDirectoryErrorApp]; usable in widget tests as-is.
class LinuxDataDirectoryErrorPage extends StatelessWidget {
  const LinuxDataDirectoryErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.wide;
    return Scaffold(
      key: LinuxDataDirectoryErrorKeys.screen,
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 48 : 24,
              vertical: wide ? 48 : 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 36,
                    color: tokens.text2,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    LinuxDataDirectoryErrorCopy.title,
                    key: LinuxDataDirectoryErrorKeys.title,
                    style: AppTypeScale.tituloTela.copyWith(color: tokens.text),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    LinuxDataDirectoryErrorCopy.body,
                    key: LinuxDataDirectoryErrorKeys.body,
                    style: AppTypeScale.definicao.copyWith(
                      color: tokens.text2,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    LinuxDataDirectoryErrorCopy.command,
                    key: LinuxDataDirectoryErrorKeys.command,
                    style: AppTypeScale.mono13.copyWith(
                      color: tokens.text,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
