import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'settings_controller.dart';

/// `/settings` — **Ajustes**. Debug Drift hello lives here (was on Home).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hello = ref.watch(helloMetaProvider);
    return Scaffold(
      backgroundColor: context.tokens.bg,
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          hello.when(
            data: (value) => Card(
              child: ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Drift + Riverpod'),
                subtitle: Text('app_meta.hello = $value'),
              ),
            ),
            loading: () => const Card(
              child: ListTile(
                leading: CircularProgressIndicator(),
                title: Text('Abrindo banco…'),
              ),
            ),
            error: (error, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Falha no Drift hello'),
                subtitle: Text('$error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
