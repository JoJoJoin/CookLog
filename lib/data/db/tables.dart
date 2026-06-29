import 'package:drift/drift.dart';

/// 菜谱表。
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  BoolColumn get wantToCook =>
      boolean().withDefault(const Constant(false))();
  TextColumn get sourceType => text().withDefault(const Constant('none'))();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get sourceAuthor => text().nullable()();
  TextColumn get steps => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get coverMediaId => text().nullable()();
  IntColumn get rating => integer().nullable()();
  IntColumn get cookCount => integer().withDefault(const Constant(0))();
  IntColumn get lastCookedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 做菜记录表。
class CookingLogs extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId => text().nullable()();
  IntColumn get cookedAt => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get improvements => text().nullable()();
  IntColumn get rating => integer().nullable()();
  TextColumn get mood => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 标签表。
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('custom'))();
  IntColumn get color => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 菜谱-标签关联表（多对多）。
class RecipeTags extends Table {
  TextColumn get recipeId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {recipeId, tagId};
}

/// 食材项表。
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId => text()();
  TextColumn get name => text()();
  TextColumn get amount => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 图片/媒体表（多态：recipe / cooking_log）。
class MediaItems extends Table {
  TextColumn get id => text()();
  TextColumn get ownerType => text()();
  TextColumn get ownerId => text()();
  TextColumn get filePath => text()();
  TextColumn get thumbPath => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 应用元数据键值表。
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
