import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_controller.dart';

/// 全局互斥：更新对话框是否已在前台，避免根监听与手动检查重复弹出。
bool updateDialogShowing = false;

/// 放在应用根部，监听自更新状态：发现新版本时弹出更新对话框。
///
/// 「已是最新 / 出错」的即时反馈由触发方（设置页按钮）负责，避免自动检查打扰用户。
class UpdateListener extends ConsumerStatefulWidget {
  const UpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateListener> createState() => _UpdateListenerState();
}

class _UpdateListenerState extends ConsumerState<UpdateListener> {
  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateStatus>(updateControllerProvider, (prev, next) {
      if (next is UpdateAvailable && !updateDialogShowing) {
        _openDialog(next.forced);
      }
    });
    return widget.child;
  }

  Future<void> _openDialog(bool forced) async {
    updateDialogShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: !forced,
      builder: (_) => UpdateDialog(forced: forced),
    );
    updateDialogShowing = false;
  }
}

/// 自更新对话框：随状态机展示「新版本信息 → 下载进度 → 安装 / 出错」。
class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key, required this.forced});

  final bool forced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);

    return PopScope(
      canPop: !forced,
      child: switch (status) {
        UpdateAvailable(:final info) => AlertDialog(
            title: Text('发现新版本 ${info.versionName}'),
            content: SingleChildScrollView(
              child: Text(
                info.changelog.isEmpty ? '建议更新到最新版本。' : info.changelog,
              ),
            ),
            actions: [
              if (!forced)
                TextButton(
                  onPressed: () {
                    controller.dismiss();
                    Navigator.of(context).pop();
                  },
                  child: const Text('稍后'),
                ),
              FilledButton(
                onPressed: () => controller.download(info, forced: forced),
                child: const Text('立即更新'),
              ),
            ],
          ),
        UpdateDownloading(:final progress) => AlertDialog(
            title: const Text('正在下载更新'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: progress > 0 ? progress : null),
                const SizedBox(height: 12),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
          ),
        UpdateReadyToInstall(:final apk) => AlertDialog(
            title: const Text('下载完成'),
            content: const Text('安装包已校验通过，点击安装更新。'),
            actions: [
              FilledButton(
                onPressed: () => controller.install(apk),
                child: const Text('安装'),
              ),
            ],
          ),
        UpdateError(:final message) => AlertDialog(
            title: const Text('更新失败'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  controller.dismiss();
                  Navigator.of(context).pop();
                },
                child: const Text('关闭'),
              ),
            ],
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
