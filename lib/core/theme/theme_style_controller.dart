import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'app_theme.dart';

/// 全局主题风格控制器：负责读取与持久化样式选择。
final themeStyleControllerProvider =
    NotifierProvider<ThemeStyleController, AppThemeStyle>(
  ThemeStyleController.new,
);

class ThemeStyleController extends Notifier<AppThemeStyle> {
  @override
  AppThemeStyle build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.themeStyle;
  }

  Future<void> setStyle(AppThemeStyle style) async {
    if (state == style) return;
    state = style;
    await ref.read(preferencesServiceProvider).setThemeStyle(style);
  }
}
