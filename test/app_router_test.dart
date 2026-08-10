import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/routing/app_router.dart';

void main() {
  test('media preview has an independent nested route', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    router.goNamed(
      AppRoute.mediaPreview.name,
      queryParameters: {'path': '/gallery/video.mp4'},
    );
    await Future<void>.delayed(Duration.zero);

    expect(router.routeInformationProvider.value.uri.path, '/gallery/preview');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['path'],
      '/gallery/video.mp4',
    );

    router.goNamed(AppRoute.gallery.name);
    await Future<void>.delayed(Duration.zero);
    expect(router.routeInformationProvider.value.uri.path, '/gallery');
  });
}
