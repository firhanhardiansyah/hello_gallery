import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/media_preview/presentation/notifiers/media_preview_notifier.dart';

void main() {
  late ProviderContainer container;
  late MediaPreviewNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    container.listen(mediaPreviewNotifierProvider, (_, _) {});
    notifier = container.read(mediaPreviewNotifierProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('keeps rotation per media while rotation lock is disabled', () async {
    await notifier.configure(_items, 0);

    notifier
      ..rotateActiveMedia()
      ..rotateActiveMedia();
    await notifier.select(1);

    final state = container.read(mediaPreviewNotifierProvider);
    expect(state.rotationFor(_items.first.path), 2);
    expect(state.rotationFor(_items.last.path), 0);
  });

  test('applies locked rotation across previous and next media', () async {
    await notifier.configure(_items, 0);

    notifier
      ..rotateActiveMedia()
      ..toggleRotationLock();
    await notifier.select(1);

    var state = container.read(mediaPreviewNotifierProvider);
    expect(state.rotationFor(_items.first.path), 1);
    expect(state.rotationFor(_items.last.path), 1);

    notifier.rotateActiveMedia();
    state = container.read(mediaPreviewNotifierProvider);
    expect(state.rotationFor(_items.first.path), 2);
    expect(state.rotationFor(_items.last.path), 2);
  });

  test('keeps locked rotation on the active media when unlocked', () async {
    await notifier.configure(_items, 0);

    notifier
      ..rotateActiveMedia()
      ..toggleRotationLock();
    await notifier.select(1);
    notifier
      ..rotateActiveMedia()
      ..toggleRotationLock();

    final state = container.read(mediaPreviewNotifierProvider);
    expect(state.isRotationLocked, isFalse);
    expect(state.rotationFor(_items.first.path), 1);
    expect(state.rotationFor(_items.last.path), 2);
  });

  test('configure resets rotation for a new preview session', () async {
    await notifier.configure(_items, 0);
    notifier
      ..rotateActiveMedia()
      ..toggleRotationLock();

    await notifier.configure(_items.reversed.toList(), 0);

    final state = container.read(mediaPreviewNotifierProvider);
    expect(state.isRotationLocked, isFalse);
    expect(state.lockedRotationQuarterTurns, 0);
    expect(state.rotationByMediaPath, isEmpty);
  });
}

final _items = [
  MediaItem(
    path: '/gallery/a.jpg',
    name: 'a.jpg',
    modifiedAt: DateTime(2026),
    mediaType: GalleryItemType.image,
  ),
  MediaItem(
    path: '/gallery/b.jpg',
    name: 'b.jpg',
    modifiedAt: DateTime(2026),
    mediaType: GalleryItemType.image,
  ),
];
