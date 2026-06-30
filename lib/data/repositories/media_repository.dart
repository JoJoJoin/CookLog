import 'package:drift/drift.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../services/media_storage_service.dart';

const _uuid = Uuid();

int _now() => DateTime.now().millisecondsSinceEpoch;

/// 图片仓库：选取→压缩落盘→入库，按 owner 查询，删除时同步清文件。
class MediaRepository {
  MediaRepository(this._db, this._storage);

  final AppDatabase _db;
  final MediaStorageService _storage;

  /// 监听某 owner（recipe/cooking_log）的图片，按排序展示。
  Stream<List<MediaItem>> watchForOwner(String ownerType, String ownerId) {
    return (_db.select(_db.mediaItems)
          ..where((m) =>
              m.ownerType.equals(ownerType) & m.ownerId.equals(ownerId))
          ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
        .watch();
  }

  /// 监听某菜谱的封面图：取「最近一次有照片的做菜记录」的首张照片，
  /// 没有任何做菜照片时返回 null（用默认图标兜底）。
  Stream<String?> watchRecipeCover(String recipeId) {
    final query = _db.select(_db.mediaItems).join([
      innerJoin(
        _db.cookingLogs,
        _db.cookingLogs.id.equalsExp(_db.mediaItems.ownerId),
      ),
    ])
      ..where(_db.mediaItems.ownerType.equals('cooking_log') &
          _db.cookingLogs.recipeId.equals(recipeId) &
          _db.cookingLogs.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.desc(_db.cookingLogs.cookedAt),
        OrderingTerm.asc(_db.mediaItems.sortOrder),
      ])
      ..limit(1);
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final m = rows.first.readTable(_db.mediaItems);
      return m.thumbPath ?? m.filePath;
    });
  }

  /// 选取多张图片，压缩落盘并写入媒体表，返回新增条数。
  Future<int> addImages(
      String ownerType, String ownerId, List<XFile> files) async {
    var added = 0;
    for (final f in files) {
      final stored = await _storage.store(f);
      await _db.into(_db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: _uuid.v4(),
              ownerType: ownerType,
              ownerId: ownerId,
              filePath: stored.filePath,
              thumbPath: Value(stored.thumbPath),
              width: Value(stored.width),
              height: Value(stored.height),
              sortOrder: Value(added),
              createdAt: _now(),
            ),
          );
      added++;
    }
    return added;
  }

  Future<void> delete(MediaItem item) async {
    await (_db.delete(_db.mediaItems)..where((m) => m.id.equals(item.id))).go();
    await _storage.deleteFiles(item.filePath, item.thumbPath);
  }
}
