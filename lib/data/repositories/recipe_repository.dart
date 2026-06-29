import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/preset_tags.dart';
import '../db/database.dart';
import '../models/enums.dart';

const _uuid = Uuid();

int _now() => DateTime.now().millisecondsSinceEpoch;

/// 菜谱仓库：菜谱 CRUD、想做清单、预置标签初始化。
class RecipeRepository {
  RecipeRepository(this._db);

  final AppDatabase _db;

  /// 首次启动写入预置标签（幂等）。
  Future<void> ensurePresetTags() async {
    final count = await _db.tags.count().getSingle();
    if (count > 0) return;
    final now = _now();
    await _db.batch((b) {
      b.insertAll(
        _db.tags,
        kPresetTags
            .map(
              (t) => TagsCompanion.insert(
                id: t.id,
                name: t.name,
                category: Value(t.category),
                createdAt: now,
                updatedAt: now,
              ),
            )
            .toList(),
      );
    });
  }

  /// 监听全部未删除菜谱（最近更新优先）。
  Stream<List<Recipe>> watchAll() {
    return (_db.select(_db.recipes)
          ..where((r) => r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .watch();
  }

  /// 监听想做清单。
  Stream<List<Recipe>> watchWantToCook() {
    return (_db.select(_db.recipes)
          ..where((r) => r.deletedAt.isNull() & r.wantToCook.equals(true))
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .watch();
  }

  Future<Recipe?> findById(String id) {
    return (_db.select(_db.recipes)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// 新建「想做」菜谱，返回 id。
  Future<String> createWantToCook({
    required String title,
    String? description,
    SourceType sourceType = SourceType.none,
    String? sourceUrl,
    String? sourceAuthor,
  }) async {
    final id = _uuid.v4();
    final now = _now();
    await _db.into(_db.recipes).insert(
          RecipesCompanion.insert(
            id: id,
            title: title,
            status: Value(RecipeStatus.wantToCook.value),
            wantToCook: const Value(true),
            sourceType: Value(sourceType.value),
            sourceUrl: Value(sourceUrl),
            sourceAuthor: Value(sourceAuthor),
            description: Value(description),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// 软删除。
  Future<void> softDelete(String id) {
    return (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(deletedAt: Value(_now()), updatedAt: Value(_now())),
    );
  }
}
