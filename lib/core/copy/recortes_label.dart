/// Portuguese crop-count copy. Singular at 1, plural from 2.
abstract final class RecortesLabel {
  static String count(int n) => n == 1 ? '1 recorte' : '$n recortes';
}
