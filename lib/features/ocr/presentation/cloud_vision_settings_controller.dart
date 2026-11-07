import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/ocr_repository.dart';
import '../domain/cloud_vision_exception.dart';

part 'cloud_vision_settings_controller.g.dart';

class CloudVisionSettingsState {
  const CloudVisionSettingsState({
    required this.keyringAvailable,
    required this.hasKey,
    required this.enabled,
    required this.privacyAccepted,
  });

  final bool keyringAvailable;
  final bool hasKey;
  final bool enabled;
  final bool privacyAccepted;
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
    final key = await store.readApiKey();
    final hasKey = key != null && key.isNotEmpty;
    final enabled = hasKey && await store.isEnabled;
    if (!hasKey && await store.isEnabled) {
      await store.setEnabled(false);
    }
    return CloudVisionSettingsState(
      keyringAvailable: await store.isKeyringAvailable,
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
    await ref.read(cloudVisionStoreProvider).writeApiKey(trimmed);
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
