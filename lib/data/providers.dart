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

/// 全部做菜记录流。
final allCookingLogsProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(cookingLogRepositoryProvider).watchAll();
});
