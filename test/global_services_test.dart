import 'package:flutter_test/flutter_test.dart';
import 'package:podium/app/modules/global/services/app_version_checker.dart';
import 'package:podium/app/modules/global/services/deep_links.dart';

void main() {
  group('DeepLink', () {
    test('reads outpost ids', () {
      expect(DeepLink.outpostId('/outpost-detail/abc-123'), 'abc-123');
      expect(DeepLink.outpostId('/outpost-detail/abc/'), 'abc');
      expect(DeepLink.outpostId('/outpost-detail'), isNull);
      expect(DeepLink.outpostId('/referral/abc'), isNull);
    });

    test('reads referrer ids without the leading slash', () {
      expect(DeepLink.referrerId('/referral/u1'), 'u1');
      expect(DeepLink.referrerId('/referral'), isNull);
      expect(DeepLink.referrerId('/outpost-detail/x'), isNull);
    });
  });

  group('isNewerVersion', () {
    test('compares numerically, not lexically', () {
      expect(isNewerVersion('1.10.0', '1.9.9'), isTrue);
      expect(isNewerVersion('1.9.9', '1.10.0'), isFalse);
    });

    test('equal versions are not newer, missing parts count as 0', () {
      expect(isNewerVersion('1.3.7', '1.3.7'), isFalse);
      expect(isNewerVersion('1.3', '1.3.0'), isFalse);
      expect(isNewerVersion('1.3.1', '1.3'), isTrue);
    });

    test('ignores build numbers and tolerates junk', () {
      expect(isNewerVersion('1.3.7', '1.3.7+171'), isFalse);
      expect(isNewerVersion('1.3.8', '1.3.7+171'), isTrue);
      expect(isNewerVersion('beta', '1.0.0'), isFalse);
    });
  });
}
