/// 首次启动写入的预置标签（id 固定，便于备份/迁移稳定）。
class PresetTag {
  const PresetTag(this.id, this.name, this.category);

  final String id;
  final String name;
  final String category;
}

const List<PresetTag> kPresetTags = [
  // 菜系
  PresetTag('t-cuisine-home', '家常', 'cuisine'),
  PresetTag('t-cuisine-sichuan', '川菜', 'cuisine'),
  PresetTag('t-cuisine-canton', '粤菜', 'cuisine'),
  PresetTag('t-cuisine-western', '西餐', 'cuisine'),
  PresetTag('t-cuisine-japanese', '日料', 'cuisine'),
  // 口味
  PresetTag('t-taste-spicy', '麻辣', 'taste'),
  PresetTag('t-taste-light', '清淡', 'taste'),
  PresetTag('t-taste-sweetsour', '酸甜', 'taste'),
  PresetTag('t-taste-savory', '香辣', 'taste'),
  // 场景
  PresetTag('t-scene-fast', '快手菜', 'scene'),
  PresetTag('t-scene-guest', '宴客', 'scene'),
  PresetTag('t-scene-breakfast', '早餐', 'scene'),
  PresetTag('t-scene-rice', '下饭', 'scene'),
  PresetTag('t-scene-soup', '汤羹', 'scene'),
];
