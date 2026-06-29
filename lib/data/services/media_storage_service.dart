import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// 落盘后的图片：原图 + 缩略图路径与尺寸。
class StoredImage {
  StoredImage({
    required this.filePath,
    required this.thumbPath,
    this.width,
    this.height,
  });

  final String filePath;
  final String thumbPath;
  final int? width;
  final int? height;
}

/// 图片服务：从相册/相机选取，压缩后落盘到应用文档目录，并生成缩略图。
class MediaStorageService {
  final ImagePicker _picker = ImagePicker();

  Future<List<XFile>> pickFromGallery() => _picker.pickMultiImage();

  Future<XFile?> pickFromCamera() =>
      _picker.pickImage(source: ImageSource.camera);

  Future<Directory> _mediaDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'media'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 压缩原图（长边≤1600、质量85）并落盘，再生成 320 宽缩略图。
  Future<StoredImage> store(XFile picked) async {
    final dir = await _mediaDir();
    final id = _uuid.v4();
    final fullPath = p.join(dir.path, '$id.jpg');
    final thumbPath = p.join(dir.path, '${id}_t.jpg');

    final full = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      fullPath,
      minWidth: 1600,
      minHeight: 1600,
      quality: 85,
    );
    await FlutterImageCompress.compressAndGetFile(
      picked.path,
      thumbPath,
      minWidth: 320,
      minHeight: 320,
      quality: 70,
    );
    return StoredImage(
      filePath: full?.path ?? fullPath,
      thumbPath: thumbPath,
    );
  }

  /// 删除图片文件（原图+缩略图），忽略不存在。
  Future<void> deleteFiles(String filePath, String? thumbPath) async {
    for (final path in [filePath, thumbPath]) {
      if (path == null) continue;
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
  }
}
