import 'package:flutter/material.dart';

/// 应用主题：Material 3 + 温暖的番茄红种子色，呼应「食物 / 厨房」情绪。
class AppTheme {
  AppTheme._();

  /// 番茄红种子色。
  static const Color _seed = Color(0xFFE8543F);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
