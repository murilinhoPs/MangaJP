import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key + toggle + privacy. The API key never goes to Drift / prefs / backup.
abstract class CloudVisionStore {
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
    this.storedKey,
    this.enabledFlag = false,
    this.privacyAcceptedFlag = false,
  });

  bool keyringAvailable;
  String? storedKey;
  bool enabledFlag;
  bool privacyAcceptedFlag;

  @override
  Future<bool> get isKeyringAvailable async => keyringAvailable;

  @override
  Future<String?> readApiKey() async => storedKey;

  @override
  Future<void> writeApiKey(String value) async {
    if (!keyringAvailable) {
      throw StateError('keyring unavailable');
    }
    storedKey = value;
  }

  @override
  Future<void> deleteApiKey() async {
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
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _prefs = prefs ?? SharedPreferences.getInstance;

  static const apiKeyStorageKey = 'cloud_vision_api_key';
  static const enabledPref = 'ocr.cloud_vision.enabled';
  static const privacyPref = 'ocr.cloud_vision.privacy_accepted';

  final FlutterSecureStorage _storage;
  final Future<SharedPreferences> Function() _prefs;

  static const _pluginTimeout = Duration(milliseconds: 400);

  Future<T?> _guard<T>(Future<T> Function() run) async {
    try {
      return await run().timeout(_pluginTimeout);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> get isKeyringAvailable async {
    if (kIsWeb) {
      return false;
    }
    final ok = await _guard(() async {
      await _storage.read(key: apiKeyStorageKey);
      return true;
    });
    return ok ?? false;
  }

  @override
  Future<String?> readApiKey() async {
    if (!await isKeyringAvailable) {
      return null;
    }
    final value = await _guard(() => _storage.read(key: apiKeyStorageKey));
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  @override
  Future<void> writeApiKey(String value) async {
    if (!await isKeyringAvailable) {
      throw StateError('keyring unavailable');
    }
    final ok = await _guard(() async {
      await _storage.write(key: apiKeyStorageKey, value: value);
      return true;
    });
    if (ok != true) {
      throw StateError('keyring unavailable');
    }
  }

  @override
  Future<void> deleteApiKey() async {
    await _guard(() async {
      await _storage.delete(key: apiKeyStorageKey);
      return true;
    });
  }

  @override
  Future<bool> get isEnabled async {
    final prefs = await _guard(_prefs);
    return prefs?.getBool(enabledPref) ?? false;
  }

  @override
  Future<void> setEnabled(bool value) async {
    final prefs = await _guard(_prefs);
    await prefs?.setBool(enabledPref, value);
  }

  @override
  Future<bool> get privacyAccepted async {
    final prefs = await _guard(_prefs);
    return prefs?.getBool(privacyPref) ?? false;
  }

  @override
  Future<void> setPrivacyAccepted(bool value) async {
    final prefs = await _guard(_prefs);
    await prefs?.setBool(privacyPref, value);
  }
}
