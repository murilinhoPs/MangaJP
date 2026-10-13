import 'package:flutter_test/flutter_test.dart';
import 'package:manga_jp/core/router/app_router.dart';

void main() {
  test('release ignores dart-define initial location', () {
    expect(
      resolveMangaJpInitialLocation(defined: '/pages/demo-page', release: true),
      '/home',
    );
  });

  test('debug allows known shot routes', () {
    expect(
      resolveMangaJpInitialLocation(defined: '/review', release: false),
      '/review',
    );
    expect(
      resolveMangaJpInitialLocation(
        defined: '/pages/demo-page',
        release: false,
      ),
      '/pages/demo-page',
    );
  });

  test('unknown or empty path falls back to /home', () {
    expect(resolveMangaJpInitialLocation(defined: '', release: false), '/home');
    expect(
      resolveMangaJpInitialLocation(defined: '/not-a-route', release: false),
      '/home',
    );
    expect(
      resolveMangaJpInitialLocation(defined: '/pages/../etc', release: false),
      '/home',
    );
  });
}
