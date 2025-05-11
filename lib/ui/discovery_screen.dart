import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ble_manager.dart';
import '../models/models.dart';
import '../ad_manager.dart' as ad_mgr;
import 'chat_screen.dart';
import 'dart:async';
import 'package:flutter/services.dart';

// Discovery screen: BLE-powered user carousel
class DiscoveryScreen extends StatefulWidget {
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final BleManager _bleManager = BleManager();
  bool _ghostMode = false;
  DateTime? _ghostModeEnd;
  Timer? _ghostModeTimer;
  Duration _ghostModeRemaining = Duration.zero;
  Set<String> _waved = {};
  String? _mutualWavePseudonym;
  Map<String, double> _liveRssi = {};
  StreamSubscription? _proximitySub;
  models.AdBanner? _adBanner;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _bleManager.onMutualWave().listen((pseudonym) async {
      setState(() {
        _mutualWavePseudonym = pseudonym;
        _showConfetti = true;
      });
      HapticFeedback.heavyImpact();
      await Future.delayed(Duration(milliseconds: 1200));
      setState(() => _showConfetti = false);
    });
    // Fetch ad banner for discovery screen
    ad_mgr.AdManager().fetchBannerAd().then((ad) {
      setState(() {
        _adBanner = ad;
      });
    });
  }

  void _startGhostModeTimer() {
    _ghostModeEnd = DateTime.now().add(Duration(minutes: 30));
    _ghostModeTimer?.cancel();
    _ghostModeTimer = Timer.periodic(Duration(seconds: 1), (_) {
      final remaining = _ghostModeEnd!.difference(DateTime.now());
      setState(() {
        _ghostModeRemaining =
            remaining > Duration.zero ? remaining : Duration.zero;
      });
      if (_ghostModeRemaining == Duration.zero) {
        setState(() => _ghostMode = false);
        _bleManager.disableInvisibleMode(User(pseudonym: 'Me'));
        _ghostModeTimer?.cancel();
      }
    });
  }

  void _subscribeProximity(List<User> users) {
    _proximitySub?.cancel();
    _liveRssi.clear();
    for (final user in users) {
      _bleManager.onProximityChanged(user.pseudonym).listen((rssi) {
        setState(() {
          _liveRssi[user.pseudonym] = rssi;
        });
      });
    }
  }

  @override
  void dispose() {
    _proximitySub?.cancel();
    _ghostModeTimer?.cancel();
    super.dispose();
  }

  Color _proximityColor(double rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.yellow;
    return Colors.red;
  }

  String _proximityLabel(double rssi) {
    if (rssi > -60) return 'Close';
    if (rssi > -80) return 'Nearby';
    return 'Far';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F2027),
            Color(0xFF2C5364),
            Color(0xFFFC466B),
            Color(0xFF3A1C71),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text('Discover'),
              actions: [
                Row(
                  children: [
                    if (_ghostMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.ghost, color: Colors.blueAccent),
                            SizedBox(width: 4),
                            Text(
                              _ghostModeRemaining.inMinutes > 0
                                  ? '${_ghostModeRemaining.inMinutes}m'
                                  : '${_ghostModeRemaining.inSeconds}s',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: Text('👻', style: TextStyle(fontSize: 24)),
                      tooltip: _ghostMode ? 'Ghost Mode ON' : 'Ghost Mode OFF',
                      onPressed: () async {
                        setState(() => _ghostMode = !_ghostMode);
                        if (_ghostMode) {
                          await _bleManager.enableInvisibleMode();
                          _startGhostModeTimer();
                        } else {
                          _ghostModeTimer?.cancel();
                          await _bleManager.disableInvisibleMode(
                            User(pseudonym: 'Me'),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            body: StreamBuilder<List<User>>(
              stream: _bleManager.getNearbyUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!;
                _subscribeProximity(users);
                if (users.isEmpty) {
                  return Center(child: Text('No users nearby'));
                }
                return PageView.builder(
                  itemCount: users.length,
                  controller: PageController(viewportFraction: 0.85),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final rssi =
                        _liveRssi[user.pseudonym] ??
                        _bleManager.getProximity(user.pseudonym);
                    final waved = _waved.contains(user.pseudonym);
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 32, horizontal: 8),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              child: Text(user.pseudonym[0]),
                            ),
                            SizedBox(height: 12),
                            Text(
                              user.pseudonym,
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            if (user.bio != null) ...[
                              SizedBox(height: 4),
                              Text(
                                user.bio!,
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: _proximityColor(rssi),
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(_proximityLabel(rssi)),
                              ],
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(
                                waved ? Icons.favorite : Icons.waving_hand,
                              ),
                              label: Text(waved ? 'Waved' : 'Wave'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: waved ? Colors.pink : null,
                              ),
                              onPressed:
                                  waved
                                      ? null
                                      : () async {
                                        setState(
                                          () => _waved.add(user.pseudonym),
                                        );
                                        await _bleManager.sendWave(
                                          user.pseudonym,
                                        );
                                        // TODO: Show animation and check for mutual wave
                                      },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            bottomNavigationBar:
                _adBanner == null
                    ? Container(
                      height: 64,
                      child: Center(child: Text('Ad banner loading...')),
                    )
                    : GestureDetector(
                      onTap: () async {
                        await ad_mgr.AdManager().openAdInAppBrowser(
                          _adBanner!.linkUrl,
                        );
                      },
                      child: Container(
                        height: 64,
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _adBanner!.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
          ),
          if (_mutualWavePseudonym != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showConfetti)
                        Icon(Icons.celebration, color: Colors.pink, size: 96),
                      SizedBox(height: 16),
                      Text(
                        'Mutual wave with $_mutualWavePseudonym!\nChat starts now; will expire if you part ways.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to ChatScreen with this user
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => ChatScreen(
                                    peerPseudonym: _mutualWavePseudonym!,
                                  ),
                            ),
                          );
                          setState(() => _mutualWavePseudonym = null);
                        },
                        child: Text('Start Chat'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
