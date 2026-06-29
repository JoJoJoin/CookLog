import 'package:cooklog/data/db/database.dart';
import 'package:cooklog/data/models/enums.dart';
import 'package:cooklog/data/repositories/cooking_log_repository.dart';
import 'package:cooklog/data/repositories/recipe_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository recipes;
  late CookingLogRepository logs;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recipes = RecipeRepository(db);
    logs = CookingLogRepository(db);
  });

  tearDown(() => db.close());

  Future<int> cook(String id) =>
      logs.create(recipeId: id, cookedAt: DateTime.now().millisecondsSinceEpoch)
          .then((_) async => (await recipes.findById(id))!.status);

  test('首次做菜：想做 → 已做并移出清单', () async {
    final id = await recipes.createWantToCook(title: '红烧肉');
    expect((await recipes.findById(id))!.status, RecipeStatus.wantToCook.value);
    await cook(id);
    final r = await recipes.findById(id);
    expect(r!.status, RecipeStatus.cooked.value);
    expect(r.wantToCook, false);
    expect(r.cookCount, 1);
  });

  test('达阈值升「常做」', () async {
    final id = await recipes.createWantToCook(title: '番茄炒蛋');
    for (var i = 0; i < kFrequentThreshold; i++) {
      await cook(id);
    }
    final r = await recipes.findById(id);
    expect(r!.cookCount, kFrequentThreshold);
    expect(r.status, RecipeStatus.frequent.value);
  });

  test('搁置后做菜不被状态机覆盖', () async {
    final id = await recipes.createWantToCook(title: '佛跳墙');
    await recipes.setShelved(id, true);
    await cook(id);
    expect((await recipes.findById(id))!.status, RecipeStatus.shelved.value);
  });

  test('设置与清空标签', () async {
    await recipes.ensurePresetTags();
    final id = await recipes.createWantToCook(title: '宫保鸡丁');
    await recipes.setRecipeTags(id, ['t-cuisine-sichuan']);
    expect((await recipes.watchTagsForRecipe(id).first).length, 1);
    await recipes.setRecipeTags(id, []);
    expect((await recipes.watchTagsForRecipe(id).first), isEmpty);
  });

  test('关键字搜索命中标题', () async {
    await recipes.createWantToCook(title: '清蒸鲈鱼');
    await recipes.createWantToCook(title: '糖醋排骨');
    final hit = await recipes.watchFiltered(keyword: '鲈鱼').first;
    expect(hit.length, 1);
    expect(hit.first.title, '清蒸鲈鱼');
  });
}
