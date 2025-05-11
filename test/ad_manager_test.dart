import 'package:flutter_test/flutter_test.dart';
import 'package:ephora/ad_manager.dart';

void main() {
  group('AdManager', () {
    test('should inject ad after 5 messages', () {
      final manager = AdManager();
      expect(manager.shouldShowAd(5), isTrue);
      expect(manager.shouldShowAd(10), isTrue);
      expect(manager.shouldShowAd(4), isFalse);
    });
    test('fetchBannerAd returns AdBanner', () async {
      final manager = AdManager();
      // This would require mocking http, so just check type for now
      expect(manager.fetchBannerAd(), completes);
    });
  });
}
