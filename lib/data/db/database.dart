import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

/// 应用本地数据库（Drift / SQLite）。
@DriftDatabase(
  tables: [
    Recipes,
    CookingLogs,
    Tags,
    RecipeTags,
    Ingredients,
    RecipeVersions,
    MediaItems,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(recipeVersions);
          }
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(name: 'cooklog');
  }
}
