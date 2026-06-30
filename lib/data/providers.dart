import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/database.dart';
import 'repositories/cooking_log_repository.dart';
import 'repositories/media_repository.dart';
import 'repositories/recipe_repository.dart';
import 'services/media_storage_service.dart';
import 'services/preferences_service.dart';

/// SharedPreferences 实例（在 main 中预初始化后覆盖）。
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider 必须在 main 中被 override');
});

/// 偏好设置服务（更新开关、主题风格等）。
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});

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

final mediaStorageServiceProvider =
    Provider<MediaStorageService>((ref) => MediaStorageService());

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(
    ref.watch(databaseProvider),
    ref.watch(mediaStorageServiceProvider),
  );
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

/// 菜谱配方记录流（按自评分排序，最高分在前）。
final recipeVersionsProvider =
    StreamProvider.autoDispose.family((ref, String id) {
  return ref.watch(recipeRepositoryProvider).watchVersions(id);
});

/// 某 owner 的图片流（ownerType:ownerId）。
final mediaForOwnerProvider =
    StreamProvider.autoDispose.family((ref, ({String type, String id}) k) {
  return ref.watch(mediaRepositoryProvider).watchForOwner(k.type, k.id);
});

/// 回收站：已软删除的菜谱。
final trashedRecipesProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(recipeRepositoryProvider).watchTrashed();
});

/// 全部做菜记录流。
final allCookingLogsProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(cookingLogRepositoryProvider).watchAll();
});
