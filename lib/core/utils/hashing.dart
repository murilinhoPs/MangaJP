import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hex sha256 of [bytes] (image dedupe later, PRD §9.4).
String sha256Hex(Uint8List bytes) => sha256.convert(bytes).toString();
