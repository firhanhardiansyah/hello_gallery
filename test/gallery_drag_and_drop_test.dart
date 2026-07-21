import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/app/theme/app_theme.dart';
import 'package:hello_gallery/features/gallery/domain/entities/gallery_item.dart';
import 'package:hello_gallery/features/gallery/presentation/states/media_drag_payload.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/gallery_card.dart';
import 'package:hello_gallery/features/settings/domain/value_objects/app_color_theme.dart';

void main() {
  testWidgets('drops a batch media payload onto a folder card', (tester) async {
    final items = [
      _media('/gallery/source/one.jpg'),
      _media('/gallery/source/two.jpg'),
    ];
    MediaDragPayload? receivedPayload;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(
            colorTheme: AppColorTheme.indigo,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 240,
                  height: 210,
                  child: GalleryCard(
                    item: items.first,
                    dragPayload: MediaDragPayload(items),
                    onTap: () {},
                  ),
                ),
                SizedBox(
                  width: 240,
                  height: 210,
                  child: GalleryCard(
                    item: GalleryFolder(
                      path: '/gallery/target',
                      name: 'Target',
                      modifiedAt: DateTime(2026),
                    ),
                    onTap: () {},
                    onMediaDropped: (payload) => receivedPayload = payload,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final source = find.text('one.jpg');
    final target = find.text('Target');
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byKey(const ValueKey('media-drag-feedback')), findsOneWidget);
    expect(find.byKey(const ValueKey('media-drag-preview-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('media-drag-preview-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('media-drag-count')), findsOneWidget);

    await gesture.moveTo(tester.getCenter(target));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(receivedPayload?.items, items);
  });
}

MediaItem _media(String path) => MediaItem(
  path: path,
  name: path.split('/').last,
  modifiedAt: DateTime(2026),
  mediaType: GalleryItemType.image,
);
