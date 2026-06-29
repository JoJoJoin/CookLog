import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
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
    // 启动后延迟自动检查更新，不阻塞首屏。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateControllerProvider.notifier).checkForUpdate(manual: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) =>
          UpdateListener(child: child ?? const SizedBox.shrink()),
    );
  }
}
