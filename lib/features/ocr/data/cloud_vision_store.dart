import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Probe of Keychain / Keystore / libsecret.
///
/// [slow] is a 400 ms plugin timeout: the key is not treated as missing.
/// [unavailable] is an error or a missing plugin (nothing is saved in plaintext).
enum KeyringAvailability { available, slow, unavailable }

/// Plugin read/write did not finish within [FlutterCloudVisionStore.pluginTimeout].
final class KeyringSlowException implements Exception {
  const KeyringSlowException();

  @override
  String toString() => 'keyring slow';
}

/// Plugin missing, threw, or platform has no secure storage (including web).
final class KeyringUnavailableException implements Exception {
  const KeyringUnavailableException();

  @override
  String toString() => 'keyring unavailable';
}

/// Key + toggle + privacy. The API key never goes to Drift / prefs / backup.
abstract class CloudVisionStore {
  Future<KeyringAvailability> get keyringAvailability;
  Future<bool> get isKeyringAvailable;
  Future<String?> readApiKey();
  Future<void> writeApiKey(String value);
  Future<void> deleteApiKey();
  Future<bool> get isEnabled;
  Future<void> setEnabled(bool value);
  Future<bool> get privacyAccepted;
  Future<void> setPrivacyAccepted(bool value);
}

/// In-memory store for tests and `--dart-define=MANGAJP_CLOUD_VISION_SHOT=…`.
/// Never used as a production fallback when the keyring is missing.
class MemoryCloudVisionStore implements CloudVisionStore {
  MemoryCloudVisionStore({
    this.keyringAvailable = true,
    this.keyringSlow = false,
    this.storedKey,
    this.enabledFlag = false,
    this.privacyAcceptedFlag = false,
  });

  bool keyringAvailable;
  bool keyringSlow;
  String? storedKey;
  bool enabledFlag;
  bool privacyAcceptedFlag;

  @override
  Future<KeyringAvailability> get keyringAvailability async {
    if (!keyringAvailable) {
      return KeyringAvailability.unavailable;
    }
    if (keyringSlow) {
      return KeyringAvailability.slow;
    }
    return KeyringAvailability.available;
  }

  @override
  Future<bool> get isKeyringAvailable async =>
      await keyringAvailability != KeyringAvailability.unavailable;

  @override
  Future<String?> readApiKey() async {
    if (keyringSlow) {
      throw const KeyringSlowException();
    }
    return storedKey;
  }

  @override
  Future<void> writeApiKey(String value) async {
    if (!keyringAvailable) {
      throw const KeyringUnavailableException();
    }
    if (keyringSlow) {
      throw const KeyringSlowException();
    }
    storedKey = value;
  }

  @override
  Future<void> deleteApiKey() async {
    if (keyringSlow) {
      throw const KeyringSlowException();
    }
    storedKey = null;
  }

  @override
  Future<bool> get isEnabled async => enabledFlag;

  @override
  Future<void> setEnabled(bool value) async {
    enabledFlag = value;
  }

  @override
  Future<bool> get privacyAccepted async => privacyAcceptedFlag;

  @override
  Future<void> setPrivacyAccepted(bool value) async {
    privacyAcceptedFlag = value;
  }
}

/// Keychain / Keystore / libsecret for the key; SharedPreferences for flags.
class FlutterCloudVisionStore implements CloudVisionStore {
  FlutterCloudVisionStore({
    FlutterSecureStorage? storage,
    Future<SharedPreferences> Function()? prefs,
    Future<String?> Function()? readPlugin,
    Future<void> Function(String value)? writePlugin,
    Future<void> Function()? deletePlugin,
  }) : _prefs = prefs ?? SharedPreferences.getInstance {
    final plugin = storage ?? const FlutterSecureStorage();
    _readPlugin = readPlugin ?? () => plugin.read(key: apiKeyStorageKey);
    _writePlugin =
        writePlugin ??
        (value) => plugin.write(key: apiKeyStorageKey, value: value);
    _deletePlugin = deletePlugin ?? () => plugin.delete(key: apiKeyStorageKey);
  }

  static const apiKeyStorageKey = 'cloud_vision_api_key';
  static const enabledPref = 'ocr.cloud_vision.enabled';
  static const privacyPref = 'ocr.cloud_vision.privacy_accepted';
  static const pluginTimeout = Duration(milliseconds: 400);

  final Future<SharedPreferences> Function() _prefs;
  late final Future<String?> Function() _readPlugin;
  late final Future<void> Function(String value) _writePlugin;
  late final Future<void> Function() _deletePlugin;

  Future<_GuardOutcome<T>> _guard<T>(Future<T> Function() run) async {
    final future = run();
    try {
      return _GuardOutcome.ok(await future.timeout(pluginTimeout));
    } on TimeoutException {
      // The plugin may still complete later. Ignore so a late throw is not
      // an unhandled async error.
      future.ignore();
      return const _GuardOutcome.timeout();
    } catch (_) {
      return const _GuardOutcome.failed();
    }
  }

  Future<_GuardOutcome<String?>> _readRaw() {
    return _guard(_readPlugin);
  }

  @override
  Future<KeyringAvailability> get keyringAvailability async {
    if (kIsWeb) {
      return KeyringAvailability.unavailable;
    }
    final result = await _readRaw();
    if (result.timedOut) {
      return KeyringAvailability.slow;
    }
    if (result.failed) {
      return KeyringAvailability.unavailable;
    }
    return KeyringAvailability.available;
  }

  @override
  Future<bool> get isKeyringAvailable async =>
      await keyringAvailability != KeyringAvailability.unavailable;

  @override
  Future<String?> readApiKey() async {
    if (kIsWeb) {
      return null;
    }
    final result = await _readRaw();
    if (result.timedOut) {
      throw const KeyringSlowException();
    }
    if (result.failed) {
      return null;
    }
    final value = result.value;
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  @override
  Future<void> writeApiKey(String value) async {
    if (kIsWeb) {
      throw const KeyringUnavailableException();
    }
    final ok = await _guard(() async {
      await _writePlugin(value);
      return true;
    });
    if (ok.timedOut) {
      throw const KeyringSlowException();
    }
    if (ok.failed || ok.value != true) {
      throw const KeyringUnavailableException();
    }
  }

  @override
  Future<void> deleteApiKey() async {
    if (kIsWeb) {
      throw const KeyringUnavailableException();
    }
    final ok = await _guard(() async {
      await _deletePlugin();
      return true;
    });
    if (ok.timedOut) {
      throw const KeyringSlowException();
    }
    if (ok.failed || ok.value != true) {
      throw const KeyringUnavailableException();
    }
  }

  @override
  Future<bool> get isEnabled async {
    final prefs = await _guard(_prefs);
    return prefs.value?.getBool(enabledPref) ?? false;
  }

  @override
  Future<void> setEnabled(bool value) async {
    final prefs = await _guard(_prefs);
    await prefs.value?.setBool(enabledPref, value);
  }

  @override
  Future<bool> get privacyAccepted async {
    final prefs = await _guard(_prefs);
    return prefs.value?.getBool(privacyPref) ?? false;
  }

  @override
  Future<void> setPrivacyAccepted(bool value) async {
    final prefs = await _guard(_prefs);
    await prefs.value?.setBool(privacyPref, value);
  }
}

final class _GuardOutcome<T> {
  const _GuardOutcome.ok(T this.value) : timedOut = false, failed = false;
  const _GuardOutcome.timeout() : value = null, timedOut = true, failed = false;
  const _GuardOutcome.failed() : value = null, timedOut = false, failed = true;

  final T? value;
  final bool timedOut;
  final bool failed;
}
