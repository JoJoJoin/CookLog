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

  /// 监听单个菜谱。
  Stream<Recipe?> watchById(String id) {
    return (_db.select(_db.recipes)..where((r) => r.id.equals(id)))
        .watchSingleOrNull();
  }

  /// 按关键字与标签筛选（LIKE 版搜索）。空条件即全部。
  Stream<List<Recipe>> watchFiltered({String? keyword, String? tagId}) {
    final q = _db.select(_db.recipes)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]);
    if (keyword != null && keyword.trim().isNotEmpty) {
      final like = '%${keyword.trim()}%';
      q.where((r) => r.title.like(like) | r.description.like(like));
    }
    if (tagId == null) return q.watch();
    return q.watch().asyncMap((recipes) async {
      final ids = await _recipeIdsForTag(tagId);
      return recipes.where((r) => ids.contains(r.id)).toList();
    });
  }

  Future<Set<String>> _recipeIdsForTag(String tagId) async {
    final rows = await (_db.select(_db.recipeTags)
          ..where((rt) => rt.tagId.equals(tagId)))
        .get();
    return rows.map((e) => e.recipeId).toSet();
  }

  /// 监听全部标签。
  Stream<List<Tag>> watchTags() {
    return (_db.select(_db.tags)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// 监听某菜谱关联的标签。
  Stream<List<Tag>> watchTagsForRecipe(String recipeId) {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.recipeTags, _db.recipeTags.tagId.equalsExp(_db.tags.id)),
    ])
      ..where(_db.recipeTags.recipeId.equals(recipeId) &
          _db.tags.deletedAt.isNull());
    return query.watch().map(
          (rows) => rows.map((r) => r.readTable(_db.tags)).toList(),
        );
  }

  /// 覆盖设置某菜谱的标签集合。
  Future<void> setRecipeTags(String recipeId, List<String> tagIds) async {
    await _db.transaction(() async {
      await (_db.delete(_db.recipeTags)
            ..where((rt) => rt.recipeId.equals(recipeId)))
          .go();
      if (tagIds.isNotEmpty) {
        await _db.batch((b) {
          b.insertAll(
            _db.recipeTags,
            tagIds.map(
              (t) => RecipeTagsCompanion.insert(recipeId: recipeId, tagId: t),
            ),
          );
        });
      }
    });
  }

  /// 切换想做：true 加入清单（状态回想做），false 仅移出清单。
  Future<void> setWantToCook(String id, bool want) {
    return (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(
        wantToCook: Value(want),
        status: want ? Value(RecipeStatus.wantToCook.value) : const Value.absent(),
        updatedAt: Value(_now()),
      ),
    );
  }

  /// 搁置 / 取消搁置。
  Future<void> setShelved(String id, bool shelved) {
    return (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(
        status: Value(shelved
            ? RecipeStatus.shelved.value
            : RecipeStatus.cooked.value),
        wantToCook: const Value(false),
        updatedAt: Value(_now()),
      ),
    );
  }

  /// 更新基础信息。
  Future<void> updateBasic(String id,
      {String? title, String? description, int? rating}) {
    return (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(
        title: title == null ? const Value.absent() : Value(title),
        description:
            description == null ? const Value.absent() : Value(description),
        rating: rating == null ? const Value.absent() : Value(rating),
        updatedAt: Value(_now()),
      ),
    );
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
