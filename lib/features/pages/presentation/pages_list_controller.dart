import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/pages_repository.dart';
import '../domain/page_list_entry.dart';

part 'pages_list_controller.g.dart';

/// Every persisted page for `/pages`, newest first.
@riverpod
Future<List<PageListEntry>> pagesList(Ref ref) {
  return ref.watch(pagesRepositoryProvider).listPageEntries();
}
