import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

/// 轻量设置存储，封装自更新相关的本地偏好。
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _kUpdateCheckEnabled = 'update_check_enabled';
  static const _kLastUpdateCheckAt = 'last_update_check_at';
  static const _kThemeStyle = 'theme_style';

  /// 是否启用自动检查更新（默认开启）。
  bool get updateCheckEnabled => _prefs.getBool(_kUpdateCheckEnabled) ?? true;

  Future<void> setUpdateCheckEnabled(bool value) =>
      _prefs.setBool(_kUpdateCheckEnabled, value);

  /// 上次检查更新时间；从未检查返回 null。
  DateTime? get lastUpdateCheckAt {
    final millis = _prefs.getInt(_kLastUpdateCheckAt);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastUpdateCheckAt(DateTime time) =>
      _prefs.setInt(_kLastUpdateCheckAt, time.millisecondsSinceEpoch);

    /// 当前主题风格（默认番茄橙）。
    AppThemeStyle get themeStyle =>
      AppThemeStyle.fromKey(_prefs.getString(_kThemeStyle));

    Future<void> setThemeStyle(AppThemeStyle style) =>
      _prefs.setString(_kThemeStyle, style.key);
}
