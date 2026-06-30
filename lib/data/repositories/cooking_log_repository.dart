import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../models/enums.dart';

const _uuid = Uuid();

int _now() => DateTime.now().millisecondsSinceEpoch;

/// 升「常做」的累计次数阈值。
const kFrequentThreshold = 5;

/// 做菜记录仓库：记录写入并维护菜谱派生数据（做过次数、状态、最近时间）。
class CookingLogRepository {
  CookingLogRepository(this._db);

  final AppDatabase _db;

  /// 监听全部未删除做菜记录（最近做菜优先）。
  Stream<List<CookingLog>> watchAll() {
    return (_db.select(_db.cookingLogs)
          ..where((l) => l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm.desc(l.cookedAt)]))
        .watch();
  }

  /// 监听某菜谱的做菜时间线。
  Stream<List<CookingLog>> watchForRecipe(String recipeId) {
    return (_db.select(_db.cookingLogs)
          ..where(
            (l) => l.deletedAt.isNull() & l.recipeId.equals(recipeId),
          )
          ..orderBy([(l) => OrderingTerm.desc(l.cookedAt)]))
        .watch();
  }

  /// 新增做菜记录，并维护关联菜谱的 cook_count / last_cooked_at / status。
  Future<String> create({
    String? recipeId,
    required int cookedAt,
    String? notes,
    String? improvements,
    int? rating,
    String? mood,
  }) async {
    final id = _uuid.v4();
    final now = _now();
    await _db.transaction(() async {
      await _db.into(_db.cookingLogs).insert(
            CookingLogsCompanion.insert(
              id: id,
              recipeId: Value(recipeId),
              cookedAt: cookedAt,
              notes: Value(notes),
              improvements: Value(improvements),
              rating: Value(rating),
              mood: Value(mood),
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (recipeId != null) {
        await _refreshRecipeStats(recipeId, cookedAt);
      }
    });
    return id;
  }

  /// 修改一条已有做菜记录的内容（日期/评分/心得/改良），并刷新菜谱最近做菜时间。
  Future<void> update({
    required String id,
    required int cookedAt,
    String? notes,
    String? improvements,
    int? rating,
  }) async {
    await _db.transaction(() async {
      final log = await (_db.select(_db.cookingLogs)
            ..where((l) => l.id.equals(id)))
          .getSingleOrNull();
      if (log == null) return;
      await (_db.update(_db.cookingLogs)..where((l) => l.id.equals(id))).write(
        CookingLogsCompanion(
          cookedAt: Value(cookedAt),
          notes: Value(notes),
          improvements: Value(improvements),
          rating: Value(rating),
          updatedAt: Value(_now()),
        ),
      );
      if (log.recipeId != null) {
        await _recomputeLastCooked(log.recipeId!);
      }
    });
  }

  /// 重新计算菜谱的最近做菜时间（取所有未删除记录的最大 cookedAt）。
  Future<void> _recomputeLastCooked(String recipeId) async {
    final logs = await (_db.select(_db.cookingLogs)
          ..where((l) => l.deletedAt.isNull() & l.recipeId.equals(recipeId)))
        .get();
    final last = logs.isEmpty
        ? null
        : logs.map((l) => l.cookedAt).reduce((a, b) => a > b ? a : b);
    await (_db.update(_db.recipes)..where((r) => r.id.equals(recipeId))).write(
      RecipesCompanion(
        lastCookedAt: Value(last),
        updatedAt: Value(_now()),
      ),
    );
  }

  Future<void> _refreshRecipeStats(String recipeId, int cookedAt) async {
    final recipe = await (_db.select(_db.recipes)
          ..where((r) => r.id.equals(recipeId)))
        .getSingleOrNull();
    if (recipe == null) return;
    final newCount = recipe.cookCount + 1;
    final last = (recipe.lastCookedAt == null || cookedAt > recipe.lastCookedAt!)
        ? cookedAt
        : recipe.lastCookedAt!;
    // 状态流转：想做/已做 → 达阈值升「常做」，否则「已做」；搁置不自动改。
    final nextStatus = recipe.status == RecipeStatus.shelved.value
        ? recipe.status
        : (newCount >= kFrequentThreshold
            ? RecipeStatus.frequent.value
            : RecipeStatus.cooked.value);
    await (_db.update(_db.recipes)..where((r) => r.id.equals(recipeId))).write(
      RecipesCompanion(
        cookCount: Value(newCount),
        lastCookedAt: Value(last),
        wantToCook: const Value(false),
        status: Value(nextStatus),
        updatedAt: Value(_now()),
      ),
    );
  }

  /// 创建随手记（无归类菜名）：自动建一条已做菜谱再挂日志。
  Future<String> createQuick({
    required String title,
    required int cookedAt,
    String? notes,
    int? rating,
  }) async {
    final recipeId = _uuid.v4();
    final now = _now();
    await _db.into(_db.recipes).insert(
          RecipesCompanion.insert(
            id: recipeId,
            title: title,
            status: Value(RecipeStatus.cooked.value),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return create(
      recipeId: recipeId,
      cookedAt: cookedAt,
      notes: notes,
      rating: rating,
    );
  }
}
