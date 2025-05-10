import 'models/models.dart';

// Ad manager for banner ad logic
class AdManager {
  // Banner ad logic for chat/discovery
  Future<AdBanner> fetchBannerAd() async {
    // TODO: Fetch ad from cloud ad server
    throw UnimplementedError();
  }

  Stream<AdBanner> adStream({required int messageCount}) {
    // TODO: Emit ad every 5 messages
    throw UnimplementedError();
  }
}
