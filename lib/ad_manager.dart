import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'models/models.dart';

// Ad manager for banner ad logic
class AdManager {
  // Fetch banner ad from cloud ad server
  Future<AdBanner> fetchBannerAd() async {
    final resp = await http.get(Uri.parse('https://api.ephora.app/ads/banner'));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return AdBanner(imageUrl: data['imageUrl'], linkUrl: data['linkUrl']);
    }
    throw Exception('Failed to fetch ad');
  }

  // Inject a banner ad every 5 messages
  bool shouldShowAd(int messageIndex) {
    return messageIndex > 0 && messageIndex % 5 == 0;
  }

  // Open ad link in in-app browser
  Future<void> openAdInAppBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } else {
      throw Exception('Could not launch $url');
    }
  }

  // Emits a new ad every 5 messages (AC-4)
  Stream<AdBanner?> adStream(Stream<int> messageCountStream) async* {
    await for (final count in messageCountStream) {
      if (shouldShowAd(count)) {
        yield await fetchBannerAd();
      } else {
        yield null;
      }
    }
  }

  // Rendering ads in chat/discovery screens is handled in the UI layer.
}
