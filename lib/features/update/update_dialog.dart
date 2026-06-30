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
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !forced,
      child: switch (status) {
        UpdateAvailable(:final info) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
            contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            actionsPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            title: _DialogHead(
              emoji: '🚀',
              title: '发现新版本 ${info.versionName}',
              subtitle: forced ? '本次更新建议立即安装' : '建议更新到最新版本',
            ),
            content: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  info.changelog.isEmpty ? '本次版本主要是体验优化与问题修复。' : info.changelog,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
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
              FilledButton.icon(
                onPressed: () => controller.download(info, forced: forced),
                icon: const Icon(Icons.download_rounded),
                label: const Text('立即更新'),
              ),
            ],
          ),
        UpdateDownloading(:final progress) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
            contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            title: const _DialogHead(
              emoji: '📦',
              title: '正在下载更新',
              subtitle: '请稍候，下载完成后会提示安装',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: progress > 0 ? progress : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        UpdateReadyToInstall(:final apk) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
            contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            actionsPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            title: const _DialogHead(
              emoji: '✅',
              title: '下载完成',
              subtitle: '安装包已校验通过',
            ),
            content: const Text('点击安装即可升级到最新版本。'),
            actions: [
              FilledButton.icon(
                onPressed: () => controller.install(apk),
                icon: const Icon(Icons.install_mobile_rounded),
                label: const Text('安装'),
              ),
            ],
          ),
        UpdateError(:final message) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
            contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            actionsPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            title: const _DialogHead(
              emoji: '⚠️',
              title: '更新失败',
              subtitle: '网络或安装流程出现问题',
            ),
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

class _DialogHead extends StatelessWidget {
  const _DialogHead({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(emoji),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
