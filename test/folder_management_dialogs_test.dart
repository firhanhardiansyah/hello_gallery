import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_gallery/features/gallery/presentation/widgets/folder_management/folder_management_dialogs.dart';

void main() {
  testWidgets('validates a folder name before submitting', (tester) async {
    String? submittedName;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => unawaited(
                showFolderNameDialog(
                  context: context,
                  title: 'Create folder',
                  locationPath: '/gallery',
                  submitLabel: 'Create folder',
                  onSubmit: (folderName) async {
                    submittedName = folderName;
                  },
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('folder-name-field')),
      '../Anime',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create folder'));
    await tester.pump();

    expect(
      find.text('Folder name cannot contain path separators.'),
      findsOneWidget,
    );
    expect(submittedName, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('folder-name-field')),
      'Anime',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create folder'));
    await tester.pumpAndSettle();

    expect(submittedName, 'Anime');
    expect(find.byKey(const ValueKey('folder-name-field')), findsNothing);
  });
}
