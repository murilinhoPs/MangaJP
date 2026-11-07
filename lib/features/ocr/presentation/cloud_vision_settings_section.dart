import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/cloud_vision_shot.dart';
import '../domain/cloud_vision_exception.dart';
import '../domain/cloud_vision_labels.dart';
import 'cloud_vision_keys.dart';
import 'cloud_vision_settings_controller.dart';

/// Ajustes › OCR: Cloud Vision toggle, masked key, Testar / Remover chave.
class CloudVisionSettingsSection extends ConsumerStatefulWidget {
  const CloudVisionSettingsSection({super.key});

  @override
  ConsumerState<CloudVisionSettingsSection> createState() =>
      _CloudVisionSettingsSectionState();
}

class _CloudVisionSettingsSectionState
    extends ConsumerState<CloudVisionSettingsSection> {
  final _draft = TextEditingController();
  bool _didShotDialog = false;
  bool _didShotError = false;
  bool _testing = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final async = ref.watch(cloudVisionSettingsProvider);
    return async.when(
      loading: () => const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text(CloudVisionLabels.section),
        ),
      ),
      error: (error, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline),
          title: const Text(CloudVisionLabels.section),
          subtitle: Text('$error'),
        ),
      ),
      data: (state) {
        _maybeShotExtras(state);
        final canEditKey = state.keyringAvailable;
        return Card(
          key: CloudVisionKeys.section,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CloudVisionLabels.section,
                  style: AppTypeScale.ui14.copyWith(
                    color: tokens.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CloudVisionLabels.defaultEngine,
                  style: AppTypeScale.metadados12.copyWith(color: tokens.text2),
                ),
                SwitchListTile(
                  key: CloudVisionKeys.toggle,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(CloudVisionLabels.toggle),
                  subtitle: const Text(CloudVisionLabels.toggleSubtitle),
                  value: state.enabled,
                  onChanged: canEditKey
                      ? (value) => _onToggle(state, value)
                      : null,
                ),
                if (!state.keyringAvailable) ...[
                  const SizedBox(height: 8),
                  Text(
                    CloudVisionLabels.keyringUnavailable,
                    key: CloudVisionKeys.keyringWarning,
                    style: AppTypeScale.ui13.copyWith(color: tokens.danger),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  key: CloudVisionKeys.apiKey,
                  controller: _draft,
                  enabled: canEditKey,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: CloudVisionLabels.apiKey,
                    hintText: state.hasKey
                        ? CloudVisionLabels.apiKeySavedHint
                        : CloudVisionLabels.apiKeyHint,
                  ),
                  onSubmitted: (value) => _saveDraft(value),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: CloudVisionKeys.testKey,
                      onPressed: canEditKey && !_testing
                          ? () => _testKey(state)
                          : null,
                      child: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(CloudVisionLabels.testKey),
                    ),
                    TextButton(
                      key: CloudVisionKeys.removeKey,
                      onPressed: canEditKey && state.hasKey
                          ? _removeKey
                          : null,
                      child: const Text(CloudVisionLabels.removeKey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _maybeShotExtras(CloudVisionSettingsState state) {
    if (kCloudVisionShotPrivacyDialog && !_didShotDialog && state.hasKey) {
      _didShotDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPrivacyDialog();
        }
      });
    }
    if (kCloudVisionShotErrorBanner && !_didShotError) {
      _didShotError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _snack(const CloudVisionInvalidApiKey().fallbackMessage);
        }
      });
    }
  }

  Future<void> _onToggle(CloudVisionSettingsState state, bool value) async {
    if (!value) {
      await ref.read(cloudVisionSettingsProvider.notifier).setEnabled(false);
      return;
    }
    if (_draft.text.trim().isNotEmpty && !state.hasKey) {
      await _saveDraft(_draft.text);
    }
    final latest = ref.read(cloudVisionSettingsProvider).value;
    if (latest == null || !latest.hasKey) {
      _snack(CloudVisionLabels.needKeyFirst);
      return;
    }
    if (!latest.privacyAccepted) {
      final accepted = await _showPrivacyDialog();
      if (accepted != true) {
        return;
      }
      await ref.read(cloudVisionSettingsProvider.notifier).acceptPrivacy();
    }
    final on = await ref
        .read(cloudVisionSettingsProvider.notifier)
        .setEnabled(true);
    if (!on && mounted) {
      _snack(CloudVisionLabels.needKeyFirst);
    }
  }

  Future<bool?> _showPrivacyDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: CloudVisionKeys.privacyDialog,
          title: const Text(CloudVisionLabels.privacyTitle),
          content: const Text(CloudVisionLabels.privacyBody),
          actions: [
            TextButton(
              key: CloudVisionKeys.privacyDecline,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(CloudVisionLabels.privacyDecline),
            ),
            TextButton(
              key: CloudVisionKeys.privacyAccept,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(CloudVisionLabels.privacyAccept),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveDraft(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await ref.read(cloudVisionSettingsProvider.notifier).saveKey(trimmed);
    _draft.clear();
  }

  Future<void> _testKey(CloudVisionSettingsState state) async {
    if (_draft.text.trim().isNotEmpty) {
      await _saveDraft(_draft.text);
    }
    final latest = ref.read(cloudVisionSettingsProvider).value;
    if (latest == null || !latest.hasKey) {
      _snack(CloudVisionLabels.needKeyFirst);
      return;
    }
    setState(() => _testing = true);
    final error = await ref
        .read(cloudVisionSettingsProvider.notifier)
        .testKey();
    if (!mounted) {
      return;
    }
    setState(() => _testing = false);
    _snack(error == null ? CloudVisionLabels.testOk : error.testMessage);
  }

  Future<void> _removeKey() async {
    await ref.read(cloudVisionSettingsProvider.notifier).removeKey();
    _draft.clear();
    if (mounted) {
      _snack(CloudVisionLabels.keyRemoved);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
