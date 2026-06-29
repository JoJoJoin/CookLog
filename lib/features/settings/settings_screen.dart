import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../update/update_controller.dart';
import '../update/update_dialog.dart';

/// 应用当前版本信息（versionName + versionCode）。
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// 设置页：承载 M1 自更新入口（检查更新、自动检查开关）。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesServiceProvider);
    final packageInfo = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader('关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('当前版本'),
            subtitle: Text(
              packageInfo.when(
                data: (info) => '${info.version} (${info.buildNumber})',
                loading: () => '读取中…',
                error: (_, _) => '未知',
              ),
            ),
          ),
          const Divider(),
          const _SectionHeader('更新'),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('检查更新'),
            subtitle: const Text('从发布源检查是否有新版本'),
            trailing: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _checking ? null : _onCheckForUpdate,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.update),
            title: const Text('自动检查更新'),
            subtitle: const Text('启动时（每 24 小时一次）自动检查'),
            value: prefs.updateCheckEnabled,
            onChanged: (value) async {
              await prefs.setUpdateCheckEnabled(value);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onCheckForUpdate() async {
    setState(() => _checking = true);
    final controller = ref.read(updateControllerProvider.notifier);
    await controller.checkForUpdate(manual: true);
    if (!mounted) return;
    setState(() => _checking = false);

    final status = ref.read(updateControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (status is UpdateUpToDate) {
      messenger.showSnackBar(
        const SnackBar(content: Text('已是最新版本')),
      );
    } else if (status is UpdateError) {
      messenger.showSnackBar(
        SnackBar(content: Text(status.message)),
      );
    } else if (status is UpdateAvailable) {
      // 主动弹出更新对话框，不依赖根监听，保证手动检查总有反馈。
      if (!updateDialogShowing) {
        updateDialogShowing = true;
        await showDialog<void>(
          context: context,
          barrierDismissible: !status.forced,
          builder: (_) => UpdateDialog(forced: status.forced),
        );
        updateDialogShowing = false;
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}
