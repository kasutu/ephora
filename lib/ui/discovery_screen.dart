import 'package:flutter/material.dart';
import '../ble_manager.dart';
import '../models/models.dart';
import 'chat_screen.dart';

// Discovery screen: BLE-powered user carousel
class DiscoveryScreen extends StatefulWidget {
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final BleManager _bleManager = BleManager();
  bool _ghostMode = false;
  Set<String> _waved = {};
  String? _mutualWavePseudonym;

  @override
  void initState() {
    super.initState();
    _bleManager.onMutualWave().listen((pseudonym) {
      setState(() {
        _mutualWavePseudonym = pseudonym;
      });
      // TODO: Optionally auto-navigate to chat after a delay
    });
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
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('Discover'),
            actions: [
              IconButton(
                icon: Icon(_ghostMode ? Icons.ghost : Icons.ghost_outlined),
                tooltip: _ghostMode ? 'Ghost Mode ON' : 'Ghost Mode OFF',
                onPressed: () {
                  setState(() => _ghostMode = !_ghostMode);
                  // TODO: Call _bleManager.stopAdvertising() when ghost mode is ON
                },
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
              if (users.isEmpty) {
                return Center(child: Text('No users nearby'));
              }
              return PageView.builder(
                itemCount: users.length,
                controller: PageController(viewportFraction: 0.85),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final rssi = _bleManager.getProximity(user.pseudonym);
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
          bottomNavigationBar: Container(
            height: 64,
            child: Center(child: Text('Ad banner placeholder')),
            // TODO: Inject ad banner from AdManager
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
                    Icon(Icons.favorite, color: Colors.pink, size: 64),
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
    );
  }
}
