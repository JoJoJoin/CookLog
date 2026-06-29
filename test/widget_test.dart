import 'package:cooklog/data/db/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 数据层冒烟：内存库可建表并读取。UI 路由由各 feature 单测覆盖。
void main() {
  test('内存数据库可建表并读取', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final recipes = await db.select(db.recipes).get();
    expect(recipes, isEmpty);
  });
}
