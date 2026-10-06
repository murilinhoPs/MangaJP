import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Prefix for words created when JMdict has no hit (`custom:<uuid>`).
const customWordIdPrefix = 'custom:';

/// New opaque id (words, pages, cards, …).
String newId() => _uuid.v4();

/// Word id for a custom (non-JMdict) entry.
String newCustomWordId() => '$customWordIdPrefix${newId()}';
