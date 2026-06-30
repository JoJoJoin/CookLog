import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_config.dart';
import '../../data/providers.dart';
import '../../data/services/android_update_service.dart';
import '../../data/services/preferences_service.dart';
import '../../data/services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return AndroidUpdateService();
});

/// 自更新状态机。
sealed class UpdateStatus {
  const UpdateStatus();
}

/// 初始 / 空闲。
class UpdateIdle extends UpdateStatus {
  const UpdateIdle();
}

/// 正在检查。
class UpdateChecking extends UpdateStatus {
  const UpdateChecking();
}

/// 已是最新版。
class UpdateUpToDate extends UpdateStatus {
  const UpdateUpToDate();
}

/// 发现新版本，等待用户确认。
class UpdateAvailable extends UpdateStatus {
  const UpdateAvailable(this.info, {required this.forced});
  final UpdateInfo info;
  final bool forced;
}

/// 正在下载。
class UpdateDownloading extends UpdateStatus {
  const UpdateDownloading(this.info, this.progress, {required this.forced});
  final UpdateInfo info;
  final double progress;
  final bool forced;
}

/// 下载并校验完成，等待安装。
class UpdateReadyToInstall extends UpdateStatus {
  const UpdateReadyToInstall(this.info, this.apk, {required this.forced});
  final UpdateInfo info;
  final File apk;
  final bool forced;
}

/// 出错（网络 / 校验 / 权限）。
class UpdateError extends UpdateStatus {
  const UpdateError(this.message);
  final String message;
}

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateStatus>(UpdateController.new);

class UpdateController extends Notifier<UpdateStatus> {
  @override
  UpdateStatus build() => const UpdateIdle();

  UpdateService get _service => ref.read(updateServiceProvider);
  PreferencesService get _prefs => ref.read(preferencesServiceProvider);

  /// 检查更新。
  ///
  /// [manual] 为 true 表示用户手动触发：忽略检查间隔、失败时给出可见提示。
  /// 自动检查则受 [AppConfig.updateCheckInterval] 与开关约束、失败静默。
  Future<void> checkForUpdate({required bool manual}) async {
    if (!manual) {
      if (!_prefs.updateCheckEnabled) return;
      final last = _prefs.lastUpdateCheckAt;
      if (last != null &&
          DateTime.now().difference(last) < AppConfig.updateCheckInterval) {
        return;
      }
    }

    state = const UpdateChecking();
    try {
      final info = await _service.fetchLatest();
      final current = await _service.currentVersionCode();
      await _prefs.setLastUpdateCheckAt(DateTime.now());

      if (info.isNewerThan(current)) {
        state = UpdateAvailable(
          info,
          forced: info.requiresForceUpdateFrom(current),
        );
      } else {
        state = const UpdateUpToDate();
      }
    } on UpdateException catch (e) {
      state = manual ? UpdateError(e.message) : const UpdateIdle();
    } catch (e) {
      state = manual ? const UpdateError('检查更新出错，请稍后重试') : const UpdateIdle();
    }
  }

  /// 下载并校验 APK，成功后进入待安装状态。
  Future<void> download(UpdateInfo info, {required bool forced}) async {
    state = UpdateDownloading(info, 0, forced: forced);
    try {
      final apk = await _service.downloadApk(
        info,
        onProgress: (p) {
          state = UpdateDownloading(info, p, forced: forced);
        },
      );
      state = UpdateReadyToInstall(info, apk, forced: forced);
    } on UpdateException catch (e) {
      state = UpdateError(e.message);
    } catch (e) {
      state = const UpdateError('下载更新出错，请稍后重试');
    }
  }

  /// 触发系统安装。
  Future<void> install(File apk) async {
    try {
      await _service.install(apk);
    } on UpdateException catch (e) {
      state = UpdateError(e.message);
    } catch (e) {
      state = const UpdateError('安装更新出错，请稍后重试');
    }
  }

  /// 用户忽略本次更新，回到空闲。
  void dismiss() => state = const UpdateIdle();

  bool get supportsInAppInstall => _service.supportsInAppInstall;
}
