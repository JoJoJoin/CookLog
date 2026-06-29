import 'package:cooklog/data/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateInfo', () {
    final json = {
      'versionName': '1.2.0',
      'versionCode': 12,
      'minSupportedVersionCode': 5,
      'apkUrl': 'https://example.com/cooklog-1.2.0.apk',
      'fileSize': 28311552,
      'sha256': 'ABCDEF',
      'forceUpdate': false,
      'changelog': '- 修复若干问题',
      'publishedAt': '2026-06-26T12:00:00Z',
    };

    test('fromJson 正确解析并规范化 sha256 为小写', () {
      final info = UpdateInfo.fromJson(json);
      expect(info.versionName, '1.2.0');
      expect(info.versionCode, 12);
      expect(info.minSupportedVersionCode, 5);
      expect(info.sha256, 'abcdef');
      expect(info.forceUpdate, isFalse);
    });

    test('isNewerThan 基于 versionCode 比较', () {
      final info = UpdateInfo.fromJson(json);
      expect(info.isNewerThan(11), isTrue);
      expect(info.isNewerThan(12), isFalse);
      expect(info.isNewerThan(13), isFalse);
    });

    test('requiresForceUpdateFrom 低于最低支持版本时为真', () {
      final info = UpdateInfo.fromJson(json);
      expect(info.requiresForceUpdateFrom(4), isTrue);
      expect(info.requiresForceUpdateFrom(5), isFalse);
      expect(info.requiresForceUpdateFrom(11), isFalse);
    });

    test('forceUpdate=true 时强制更新', () {
      final info = UpdateInfo.fromJson({...json, 'forceUpdate': true});
      expect(info.requiresForceUpdateFrom(11), isTrue);
    });

    test('字符串型 versionCode 也能解析', () {
      final info = UpdateInfo.fromJson({...json, 'versionCode': '12'});
      expect(info.versionCode, 12);
    });
  });
}
