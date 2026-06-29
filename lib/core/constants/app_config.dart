/// 全局配置常量。
///
/// 自更新相关的托管地址在此集中维护，发布时只需更新 `version.json` 与 APK。
class AppConfig {
  AppConfig._();

  /// 应用展示名。
  static const String appName = 'CookLog';

  /// 自更新版本清单 URL。
  ///
  /// 采用 GitHub Releases 的「latest」稳定地址：上传名为 `version.json` 与
  /// `cooklog-x.y.z.apk` 的 release asset 后，下面的地址会始终指向最新 release。
  ///
  /// 也可换成 Gitee Releases 或对象存储的静态地址。
  static const String versionJsonUrl =
      'https://github.com/JoJoJoin/CookLog/releases/latest/download/version.json';

  /// 两次自动检查更新的最小间隔。
  static const Duration updateCheckInterval = Duration(hours: 24);

  /// 网络请求超时。
  static const Duration networkTimeout = Duration(seconds: 15);
}
