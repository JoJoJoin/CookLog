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

  /// GitHub 下载镜像前缀，用于国内网络访问 Releases（手机直连 github.com 常不通）。
  ///
  /// 留空字符串则直连 github.com。可按需替换为其它可用代理，例如：
  /// `https://ghfast.top/`、`https://ghproxy.net/`、`https://mirror.ghproxy.com/`。
  /// 这类公共代理稳定性会变化，若失效换一个即可；想彻底自主可改用 Gitee Releases 或对象存储。
  static const String githubMirror = 'https://gh-proxy.com/';

  /// 给 github.com / githubusercontent 链接套上 [githubMirror] 前缀。
  ///
  /// 非 GitHub 链接或镜像为空时原样返回。
  static String mirrored(String url) {
    if (githubMirror.isEmpty) return url;
    const hosts = [
      'https://github.com/',
      'https://raw.githubusercontent.com/',
      'https://release-assets.githubusercontent.com/',
      'https://objects.githubusercontent.com/',
    ];
    for (final host in hosts) {
      if (url.startsWith(host)) return '$githubMirror$url';
    }
    return url;
  }

  /// 两次自动检查更新的最小间隔。
  static const Duration updateCheckInterval = Duration(hours: 24);

  /// 网络请求超时。
  static const Duration networkTimeout = Duration(seconds: 15);
}
