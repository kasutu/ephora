import 'package:flutter/material.dart';

// Settings screen: privacy, invisible mode
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Center(child: Text('Settings UI goes here')),
    );
  }
}

// TODO: Add Privacy Center with ephemeral chat guide
// TODO: Add Ghost (Invisible) mode toggle and timer
// TODO: Add data & security info (device-only, auto-erased)
// TODO: Add logout button to clear local caches
// TODO: Integrate with AuthManager and BleManager
