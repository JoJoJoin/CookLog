import 'dart:io';

/// 远程版本清单（version.json）解析结果。
class UpdateInfo {
  const UpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.minSupportedVersionCode,
    required this.apkUrl,
    required this.fileSize,
    required this.sha256,
    required this.forceUpdate,
    required this.changelog,
    required this.publishedAt,
  });

  /// 语义化版本，用于展示，如 `1.2.0`。
  final String versionName;

  /// 单调递增整数，比较是否需要更新的权威依据。
  final int versionCode;

  /// 低于此值视为「必须更新」（如旧备份格式不兼容）。
  final int minSupportedVersionCode;

  /// APK 下载地址。
  final String apkUrl;

  /// APK 字节数（用于展示与下载校验）。
  final int fileSize;

  /// APK 的 sha256（小写十六进制），下载后校验完整性。
  final String sha256;

  /// 是否强制更新。
  final bool forceUpdate;

  /// 更新日志。
  final String changelog;

  /// 发布时间（ISO8601）。
  final String publishedAt;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      versionName: (json['versionName'] as String?)?.trim() ?? '',
      versionCode: _asInt(json['versionCode']),
      minSupportedVersionCode: _asInt(json['minSupportedVersionCode']),
      apkUrl: (json['apkUrl'] as String?)?.trim() ?? '',
      fileSize: _asInt(json['fileSize']),
      sha256: ((json['sha256'] as String?) ?? '').trim().toLowerCase(),
      forceUpdate: json['forceUpdate'] == true,
      changelog: (json['changelog'] as String?) ?? '',
      publishedAt: (json['publishedAt'] as String?) ?? '',
    );
  }

  /// 远程版本是否比本机 [currentVersionCode] 更新。
  bool isNewerThan(int currentVersionCode) => versionCode > currentVersionCode;

  /// 本机 [currentVersionCode] 是否低于最低支持版本（需强制更新）。
  bool requiresForceUpdateFrom(int currentVersionCode) =>
      forceUpdate || currentVersionCode < minSupportedVersionCode;

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

/// 自更新服务抽象。Android 提供完整实现；其它平台可空实现。
abstract class UpdateService {
  /// 拉取并解析远程版本清单；解析失败抛出异常，由调用方降级处理。
  Future<UpdateInfo> fetchLatest();

  /// 读取本机 versionCode。
  Future<int> currentVersionCode();

  /// 当前平台是否支持「下载 APK + 触发安装」的自更新方式。
  bool get supportsInAppInstall;

  /// 下载 APK 到本地临时文件，[onProgress] 回传 0..1 进度。
  ///
  /// 下载完成后会校验 sha256，不匹配则抛出 [UpdateException]。
  Future<File> downloadApk(
    UpdateInfo info, {
    void Function(double progress)? onProgress,
  });

  /// 触发系统安装器安装给定 APK（必要时引导授予安装权限）。
  Future<void> install(File apk);
}

/// 自更新过程中的可预期错误（网络、校验、权限等）。
class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;

  @override
  String toString() => 'UpdateException: $message';
}
