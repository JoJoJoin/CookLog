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
    MediaItems,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // schemaVersion 提升时在此编写迁移；当前为 v1。
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(name: 'cooklog');
  }
}
