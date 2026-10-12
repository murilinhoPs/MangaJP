import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/copy/recortes_label.dart';

void main() {
  test('1 recorte singular; plural from 2', () {
    expect(RecortesLabel.count(0), '0 recortes');
    expect(RecortesLabel.count(1), '1 recorte');
    expect(RecortesLabel.count(2), '2 recortes');
    expect(RecortesLabel.count(3), '3 recortes');
  });
}
