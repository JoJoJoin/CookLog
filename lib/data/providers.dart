import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/database.dart';
import 'repositories/cooking_log_repository.dart';
import 'repositories/recipe_repository.dart';

/// 全局数据库实例。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(databaseProvider));
});

final cookingLogRepositoryProvider = Provider<CookingLogRepository>((ref) {
  return CookingLogRepository(ref.watch(databaseProvider));
});

/// 想做清单流。
final wantToCookProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(recipeRepositoryProvider).watchWantToCook();
});

/// 全部菜谱流。
final allRecipesProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(recipeRepositoryProvider).watchAll();
});

/// 菜谱列表筛选条件（关键字 + 标签）。
final recipeKeywordProvider = StateProvider.autoDispose<String>((ref) => '');
final recipeTagFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

/// 经关键字/标签筛选后的菜谱流。
final filteredRecipesProvider = StreamProvider.autoDispose((ref) {
  final keyword = ref.watch(recipeKeywordProvider);
  final tagId = ref.watch(recipeTagFilterProvider);
  return ref
      .watch(recipeRepositoryProvider)
      .watchFiltered(keyword: keyword, tagId: tagId);
});

/// 全部标签流。
final allTagsProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(recipeRepositoryProvider).watchTags();
});

/// 单个菜谱详情流。
final recipeDetailProvider =
    StreamProvider.autoDispose.family((ref, String id) {
  return ref.watch(recipeRepositoryProvider).watchById(id);
});

/// 菜谱标签流。
final recipeTagsProvider =
    StreamProvider.autoDispose.family((ref, String id) {
  return ref.watch(recipeRepositoryProvider).watchTagsForRecipe(id);
});

/// 菜谱做菜时间线流。
final recipeLogsProvider =
    StreamProvider.autoDispose.family((ref, String id) {
  return ref.watch(cookingLogRepositoryProvider).watchForRecipe(id);
});

/// 全部做菜记录流。
final allCookingLogsProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(cookingLogRepositoryProvider).watchAll();
});
