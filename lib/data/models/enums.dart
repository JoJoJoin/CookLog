/// 菜谱状态枚举。
enum RecipeStatus {
  wantToCook(0, '想做'),
  cooked(1, '已做'),
  frequent(2, '常做'),
  shelved(3, '搁置');

  const RecipeStatus(this.value, this.label);

  final int value;
  final String label;

  static RecipeStatus fromValue(int value) {
    return RecipeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RecipeStatus.wantToCook,
    );
  }
}

/// 标签分类。
enum TagCategory {
  cuisine('cuisine', '菜系'),
  taste('taste', '口味'),
  scene('scene', '场景'),
  ingredient('ingredient', '主料'),
  custom('custom', '自定义');

  const TagCategory(this.value, this.label);

  final String value;
  final String label;

  static TagCategory fromValue(String value) {
    return TagCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TagCategory.custom,
    );
  }
}
