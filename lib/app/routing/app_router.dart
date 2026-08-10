import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/gallery/presentation/pages/gallery_page.dart';
import '../../features/gallery/presentation/pages/gallery_shell_page.dart';
import '../../features/media_preview/presentation/pages/media_preview_route_page.dart';

enum AppRoute { gallery, mediaPreview }

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/gallery',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/gallery'),
      ShellRoute(
        builder: (context, state, child) => GalleryShellPage(
          isPreviewRoute: state.uri.path == '/gallery/preview',
          previewPath: state.uri.queryParameters['path'],
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/gallery',
            name: AppRoute.gallery.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GalleryPage()),
          ),
          GoRoute(
            path: '/gallery/preview',
            name: AppRoute.mediaPreview.name,
            redirect: (context, state) =>
                state.uri.queryParameters['path'] == null ? '/gallery' : null,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MediaPreviewRoutePage()),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
