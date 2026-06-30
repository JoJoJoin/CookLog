import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_style_controller.dart';
import 'data/providers.dart';
import 'features/update/update_controller.dart';
import 'features/update/update_dialog.dart';

class CookLogApp extends ConsumerStatefulWidget {
  const CookLogApp({super.key});

  @override
  ConsumerState<CookLogApp> createState() => _CookLogAppState();
}

class _CookLogAppState extends ConsumerState<CookLogApp> {
  @override
  void initState() {
    super.initState();
    // 首次启动写入预置标签。
    ref.read(recipeRepositoryProvider).ensurePresetTags();
    // 启动后延迟自动检查更新，不阻塞首屏。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateControllerProvider.notifier).checkForUpdate(manual: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final style = ref.watch(themeStyleControllerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(style),
      darkTheme: AppTheme.dark(style),
      routerConfig: router,
      builder: (context, child) =>
          UpdateListener(child: child ?? const SizedBox.shrink()),
    );
  }
}
