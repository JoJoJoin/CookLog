import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_config.dart';
import 'update_service.dart';

/// 基于自托管 version.json + APK 的自更新实现。
///
/// 检查更新（拉取清单、读取本机版本）是跨平台的；
/// 「下载并触发安装」仅在 Android 生效。
class AndroidUpdateService implements UpdateService {
  AndroidUpdateService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: AppConfig.networkTimeout,
              receiveTimeout: AppConfig.networkTimeout,
              followRedirects: true,
            ));

  final Dio _dio;

  @override
  bool get supportsInAppInstall => Platform.isAndroid;

  @override
  Future<UpdateInfo> fetchLatest() async {
    try {
      final response = await _dio.get<dynamic>(
        AppConfig.mirrored(AppConfig.versionJsonUrl),
        options: Options(responseType: ResponseType.json),
      );
      final data = response.data;
      final Map<String, dynamic> json;
      if (data is Map<String, dynamic>) {
        json = data;
      } else if (data is String) {
        // 某些静态托管返回 text/plain，dio 不会自动解析。
        json = _decodeJson(data);
      } else {
        throw const UpdateException('版本信息格式不正确');
      }
      final info = UpdateInfo.fromJson(json);
      if (info.versionCode <= 0 || info.apkUrl.isEmpty) {
        throw const UpdateException('版本信息缺少必要字段');
      }
      return info;
    } on DioException catch (e) {
      throw UpdateException('检查更新失败：${e.message ?? '网络错误'}');
    }
  }

  @override
  Future<int> currentVersionCode() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  @override
  Future<File> downloadApk(
    UpdateInfo info, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final fileName = 'cooklog-${info.versionName}-${info.versionCode}.apk';
    final savePath = p.join(dir.path, fileName);

    // 清理可能存在的旧的不完整文件。
    final existing = File(savePath);
    if (await existing.exists()) {
      await existing.delete();
    }

    try {
      await _dio.download(
        AppConfig.mirrored(info.apkUrl),
        savePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
      );
    } on DioException catch (e) {
      throw UpdateException('下载失败：${e.message ?? '网络错误'}');
    }

    final apk = File(savePath);
    await _verifySha256(apk, info.sha256);
    return apk;
  }

  @override
  Future<void> install(File apk) async {
    if (!Platform.isAndroid) {
      throw const UpdateException('当前平台不支持应用内安装');
    }
    if (!await apk.exists()) {
      throw const UpdateException('安装包不存在，请重新下载');
    }

    // Android 8+ 需要「安装未知应用」权限。
    final status = await Permission.requestInstallPackages.request();
    if (!status.isGranted) {
      throw const UpdateException('未授予安装权限，无法安装更新');
    }

    final result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw UpdateException('唤起安装器失败：${result.message}');
    }
  }

  /// 校验下载文件的 sha256；远程未提供时跳过（但会记录）。
  Future<void> _verifySha256(File apk, String expected) async {
    if (expected.isEmpty) return;
    final digest = await _sha256OfFile(apk);
    if (digest != expected.toLowerCase()) {
      // 校验失败立即删除，避免安装被篡改/损坏的包。
      if (await apk.exists()) {
        await apk.delete();
      }
      throw const UpdateException('安装包校验失败，可能已损坏，请重试');
    }
  }

  Future<String> _sha256OfFile(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic> _decodeJson(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const UpdateException('版本信息格式不正确');
    } on FormatException {
      throw const UpdateException('版本信息解析失败');
    }
  }
}
