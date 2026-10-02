import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/deinflect/deinflector.dart';

void main() {
  test('Deinflector placeholder returns no candidates', () {
    expect(const Deinflector().candidates('食べた'), isEmpty);
  });
}
