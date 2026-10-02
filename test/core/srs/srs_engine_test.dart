import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/srs/sm2_jr.dart';

void main() {
  test('Sm2JrEngine placeholder advertises engine_id sm2-jr@1', () {
    expect(const Sm2JrEngine().engineId, 'sm2-jr@1');
  });
}
