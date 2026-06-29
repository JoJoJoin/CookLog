import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 全屏大图查看器，支持左右滑动与缩放。
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({super.key, required this.paths, this.initial = 0});

  final List<String> paths;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PhotoViewGallery.builder(
        itemCount: paths.length,
        pageController: PageController(initialPage: initial),
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: FileImage(File(paths[i])),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
      ),
    );
  }
}
