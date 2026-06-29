import 'dart:io';

import 'package:cooklog/app.dart';
import 'package:cooklog/data/services/update_service.dart';
import 'package:cooklog/features/update/update_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 测试用假实现：不触网、不依赖平台插件，恒「已是最新」。
class _FakeUpdateService implements UpdateService {
  @override
  Future<int> currentVersionCode() async => 1;

  @override
  Future<UpdateInfo> fetchLatest() async => UpdateInfo.fromJson(const {
        'versionName': '1.0.0',
        'versionCode': 1,
        'minSupportedVersionCode': 1,
        'apkUrl': 'https://example.com/a.apk',
        'fileSize': 1,
        'sha256': '',
        'forceUpdate': false,
        'changelog': '',
        'publishedAt': '',
      });

  @override
  bool get supportsInAppInstall => false;

  @override
  Future<File> downloadApk(UpdateInfo info,
          {void Function(double progress)? onProgress}) =>
      throw UnimplementedError();

  @override
  Future<void> install(File apk) => throw UnimplementedError();
}

void main() {
  testWidgets('启动后展示底部导航四个分支', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          updateServiceProvider.overrideWithValue(_FakeUpdateService()),
        ],
        child: const CookLogApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsWidgets);
    expect(find.text('想做'), findsWidgets);
    expect(find.text('菜谱'), findsWidgets);
    expect(find.text('设置'), findsWidgets);
  });
}
