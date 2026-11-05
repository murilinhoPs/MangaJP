import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/features/pages/domain/page_title.dart';

void main() {
  test('empty OCR becomes Página', () {
    expect(PageTitle.fromOcr(null), 'Página');
    expect(PageTitle.fromOcr(''), 'Página');
    expect(PageTitle.fromOcr('   '), 'Página');
  });

  test('uses the first line and truncates at 36 characters', () {
    expect(PageTitle.fromOcr('見せる\n二行目'), '見せる');
    const long = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆ';
    expect(long.length, greaterThan(36));
    expect(PageTitle.fromOcr(long), '${long.substring(0, 36)}…');
  });

  test('truncates by grapheme so a non-BMP kanji is not split', () {
    const rare = '𠮟';
    expect(rare.length, 2);
    final long = '${'あ' * 35}$rare$rare';
    final title = PageTitle.fromOcr(long);
    expect(title, '${'あ' * 35}$rare…');
    expect(title.endsWith('…'), isTrue);
  });
}
