import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/providers.dart';
import '../../core/widgets/brand_fx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_style_controller.dart';
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
    final themeStyle = ref.watch(themeStyleControllerProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: BrandBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            StaggerItem(
              index: 0,
              child: _SettingSection(
                title: '关于',
                child: _SettingCard(
                  icon: Icons.info_outline,
                  title: '当前版本',
                  subtitle: packageInfo.when(
                    data: (info) => '${info.version} (${info.buildNumber})',
                    loading: () => '读取中…',
                    error: (_, _) => '未知',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            StaggerItem(
              index: 1,
              child: _SettingSection(
                title: '数据',
                child: _SettingCard(
                  icon: Icons.delete_outline_rounded,
                  title: '回收站',
                  subtitle: '恢复或永久删除已删除的菜谱',
                  onTap: () => context.push('/recycle-bin'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            StaggerItem(
              index: 2,
              child: _SettingSection(
                title: '外观',
                child: Material(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.palette_outlined,
                                size: 20,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('主题风格'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in AppThemeStyle.values)
                              ChoiceChip(
                                label: Text(s.label),
                                selected: themeStyle == s,
                                onSelected: (_) => ref
                                    .read(themeStyleControllerProvider.notifier)
                                    .setStyle(s),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            StaggerItem(
              index: 3,
              child: _SettingSection(
                title: '更新',
                child: Column(
                  children: [
                    _SettingCard(
                      icon: Icons.system_update_alt_rounded,
                      title: '检查更新',
                      subtitle: '从发布源检查是否有新版本',
                      trailing: _checking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                      onTap: _checking ? null : _onCheckForUpdate,
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(18),
                      child: SwitchListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        secondary: const Icon(Icons.auto_mode_rounded),
                        title: const Text('自动检查更新'),
                        subtitle: const Text('启动时（每 24 小时一次）自动检查'),
                        value: prefs.updateCheckEnabled,
                        onChanged: (value) async {
                          await prefs.setUpdateCheckEnabled(value);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _SettingSection extends StatelessWidget {
  const _SettingSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
