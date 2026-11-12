import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/cloud_vision_store.dart';
import '../data/ocr_repository.dart';
import '../domain/cloud_vision_exception.dart';

part 'cloud_vision_settings_controller.g.dart';

class CloudVisionSettingsState {
  const CloudVisionSettingsState({
    required this.keyringAvailability,
    required this.hasKey,
    required this.enabled,
    required this.privacyAccepted,
  });

  final KeyringAvailability keyringAvailability;
  final bool hasKey;
  final bool enabled;
  final bool privacyAccepted;

  /// Field and toggle stay usable unless the plugin is missing / errored.
  bool get keyringAvailable =>
      keyringAvailability != KeyringAvailability.unavailable;

  bool get keyringSlow => keyringAvailability == KeyringAvailability.slow;
}

@Riverpod(keepAlive: true)
class CloudVisionSettings extends _$CloudVisionSettings {
  @override
  Future<CloudVisionSettingsState> build() {
    ref.watch(cloudVisionStoreProvider);
    return _load();
  }

  Future<CloudVisionSettingsState> _load() async {
    final store = ref.read(cloudVisionStoreProvider);
    final availability = await store.keyringAvailability;

    if (availability == KeyringAvailability.unavailable) {
      if (await store.isEnabled) {
        await store.setEnabled(false);
      }
      return CloudVisionSettingsState(
        keyringAvailability: availability,
        hasKey: false,
        enabled: false,
        privacyAccepted: await store.privacyAccepted,
      );
    }

    if (availability == KeyringAvailability.slow) {
      final enabled = await store.isEnabled;
      return CloudVisionSettingsState(
        keyringAvailability: availability,
        // A slow read does not mean the key is gone. If the toggle was on,
        // there was a key; keep that so the UI does not blank the field.
        hasKey: enabled,
        enabled: enabled,
        privacyAccepted: await store.privacyAccepted,
      );
    }

    final key = await store.readApiKey();
    final hasKey = key != null && key.isNotEmpty;
    final enabled = hasKey && await store.isEnabled;
    if (!hasKey && await store.isEnabled) {
      await store.setEnabled(false);
    }
    return CloudVisionSettingsState(
      keyringAvailability: availability,
      hasKey: hasKey,
      enabled: enabled,
      privacyAccepted: await store.privacyAccepted,
    );
  }

  Future<void> saveKey(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      await ref.read(cloudVisionStoreProvider).writeApiKey(trimmed);
    } on KeyringSlowException {
      state = AsyncData(await _load());
      rethrow;
    } on KeyringUnavailableException {
      state = AsyncData(await _load());
      rethrow;
    }
    state = AsyncData(await _load());
  }

  Future<void> removeKey() async {
    final store = ref.read(cloudVisionStoreProvider);
    await store.deleteApiKey();
    await store.setEnabled(false);
    state = AsyncData(await _load());
  }

  Future<void> acceptPrivacy() async {
    await ref.read(cloudVisionStoreProvider).setPrivacyAccepted(true);
    state = AsyncData(await _load());
  }

  /// Returns false when the toggle cannot turn on (no key / keyring).
  Future<bool> setEnabled(bool value) async {
    final current = state.value;
    if (current == null) {
      return false;
    }
    if (value) {
      if (!current.keyringAvailable || !current.hasKey) {
        return false;
      }
      await ref.read(cloudVisionStoreProvider).setEnabled(true);
    } else {
      await ref.read(cloudVisionStoreProvider).setEnabled(false);
    }
    state = AsyncData(await _load());
    return state.value?.enabled ?? false;
  }

  Future<CloudVisionException?> testKey() async {
    try {
      await ref.read(cloudVisionOcrEngineProvider).testKey();
      return null;
    } on CloudVisionException catch (error) {
      return error;
    }
  }
}
