import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/pages_repository.dart';
import '../domain/page_list_entry.dart';

part 'pages_list_controller.g.dart';

/// Every persisted page for `/pages`, newest first.
///
/// A stream so Galeria + → capture can insert while `/pages` stays mounted
/// underneath (push `/capture`, then `pushReplacement` `/pages/:id`).
@riverpod
Stream<List<PageListEntry>> pagesList(Ref ref) {
  return ref.watch(pagesRepositoryProvider).watchPageEntries();
}
