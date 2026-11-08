import 'package:flutter/widgets.dart';

/// Widget keys for Ajustes › OCR and the reader engine chip.
abstract final class CloudVisionKeys {
  static const section = Key('settings-ocr');
  static const toggle = Key('settings-ocr-cloud-toggle');
  static const apiKey = Key('settings-ocr-api-key');
  static const testKey = Key('settings-ocr-test-key');
  static const removeKey = Key('settings-ocr-remove-key');
  static const keyringWarning = Key('settings-ocr-keyring-warning');
  static const privacyDialog = Key('settings-ocr-privacy-dialog');
  static const privacyAccept = Key('settings-ocr-privacy-accept');
  static const privacyDecline = Key('settings-ocr-privacy-decline');
  static const engineChip = Key('page-ocr-engine-chip');
}
