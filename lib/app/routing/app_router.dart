import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/gallery/presentation/pages/gallery_page.dart';

enum AppRoute { gallery }

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/gallery',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/gallery'),
      GoRoute(
        path: '/gallery',
        name: AppRoute.gallery.name,
        builder: (context, state) =>
            GalleryPage(previewPath: state.uri.queryParameters['preview']),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
