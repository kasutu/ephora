import 'package:flutter/material.dart';
import '../ble_manager.dart';
import '../auth_manager.dart';
import '../local_storage.dart';
import '../models/models.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _ghostMode = false;
  final BleManager _bleManager = BleManager();
  final AuthManager _authManager = AuthManager();
  bool _reduceMotion = false;
  bool _highContrast = false;

  @override
  void initState() {
    super.initState();
    _ghostMode = _bleManager.isInvisible;
  }

  void _toggleGhostMode() async {
    setState(() => _ghostMode = !_ghostMode);
    if (_ghostMode) {
      await _bleManager.enableInvisibleMode();
    } else {
      await _bleManager.disableInvisibleMode(User(pseudonym: 'Me'));
    }
  }

  void _logout() async {
    await _authManager.logout();
    await LocalStorage.clearAll();
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          ListTile(
            leading: Text('👻', style: TextStyle(fontSize: 28)),
            title: Text('Ghost Mode'),
            subtitle: Text(
              _ghostMode ? 'Invisible for 30 min' : 'Appear in discovery',
            ),
            trailing: Switch(
              value: _ghostMode,
              onChanged: (v) => _toggleGhostMode(),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Center'),
            subtitle: Text('Ephemeral Chat Guide & Data Policy'),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: Text('Privacy Center'),
                      content: Text(
                        'All chats and media are device-only and auto-erased on expiry. No server-side logs. Ghost Mode hides you for 30 min. See FAQ for more.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
          Divider(),
          SwitchListTile(
            title: Text('Reduce Motion'),
            subtitle: Text('Minimize animations for accessibility'),
            value: _reduceMotion,
            onChanged: (v) => setState(() => _reduceMotion = v),
          ),
          SwitchListTile(
            title: Text('High Contrast'),
            subtitle: Text('Increase color contrast for readability'),
            value: _highContrast,
            onChanged: (v) => setState(() => _highContrast = v),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            subtitle: Text('Clear all local data and sign out'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
