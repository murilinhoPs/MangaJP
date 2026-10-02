import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// New opaque id (words, pages, cards, …).
String newId() => _uuid.v4();
