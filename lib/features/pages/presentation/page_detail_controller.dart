import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../words/data/words_repository.dart';
import '../../words/domain/word_state_index.dart';
import '../data/pages_repository.dart';
import '../domain/page_crop.dart';

part 'page_detail_controller.g.dart';

/// Persisted crops for `/pages/:id`. Text is read from Drift, not route extra.
@riverpod
class PageCrops extends _$PageCrops {
  @override
  Future<List<PageCrop>> build(String pageId) {
    return ref.watch(pagesRepositoryProvider).cropsForPage(pageId);
  }
}

/// Caderno states for Página token colors. Invalidate after lookup actions.
@riverpod
Future<WordStateIndex> listedWordStates(Ref ref) {
  return ref.watch(wordsRepositoryProvider).stateIndex();
}
