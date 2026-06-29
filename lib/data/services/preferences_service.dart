import 'package:shared_preferences/shared_preferences.dart';

/// 轻量设置存储，封装自更新相关的本地偏好。
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _kUpdateCheckEnabled = 'update_check_enabled';
  static const _kLastUpdateCheckAt = 'last_update_check_at';

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
}
