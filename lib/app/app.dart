import 'package:flutter/material.dart';

import '../features/gallery/gallery_page.dart';
import 'theme.dart';

class LocalGalleryApp extends StatelessWidget {
  const LocalGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Gallery',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const GalleryPage(),
    );
  }
}
