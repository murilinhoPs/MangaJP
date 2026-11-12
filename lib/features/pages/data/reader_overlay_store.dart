import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'reader_overlay_store.g.dart';

/// Global OCR overlay toggle. Key `reader.ocrOverlay`, default **on**.
@Riverpod(keepAlive: true)
class ReaderOcrOverlay extends _$ReaderOcrOverlay {
  static const prefKey = 'reader.ocrOverlay';

  @override
  bool build() {
    Future<void>.microtask(_hydrate);
    return true;
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(prefKey) ?? true;
      if (ref.mounted && state != value) {
        state = value;
      }
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, value);
    } catch (_) {}
    state = value;
  }

  Future<void> toggle() {
    return setEnabled(!state);
  }
}
