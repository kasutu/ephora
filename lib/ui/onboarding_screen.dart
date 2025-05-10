import 'package:flutter/material.dart';
import '../auth_manager.dart';
import '../models/models.dart';

// Onboarding screen: signup, PIN, profile
class OnboardingScreen extends StatefulWidget {
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  String? _pseudonym;
  String? _password;
  String? _pin;
  String? _avatarUrl;
  String? _bio;
  bool _loading = false;
  String? _error;

  void _nextStep() {
    setState(() {
      _step++;
      _error = null;
    });
  }

  void _prevStep() {
    setState(() {
      if (_step > 0) _step--;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthManager().signUp(
        _pseudonym!,
        _password!,
        pin: _pin,
      );
      // TODO: Save avatar/bio if provided
      // TODO: Navigate to discovery screen
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Onboarding')),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TODO: Add animated BLE wave splash
                if (_step == 0) ...[
                  Text('Sign Up', style: Theme.of(context).textTheme.headline6),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Pseudonym'),
                    onSaved: (v) => _pseudonym = v,
                    validator:
                        (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onSaved: (v) => _password = v,
                    validator:
                        (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message:
                            'Why anonymous? Ephora never stores real names. Learn more in our privacy FAQ.',
                        child: Icon(Icons.info_outline),
                      ),
                    ],
                  ),
                  ElevatedButton(onPressed: _nextStep, child: Text('Next')),
                ] else if (_step == 1) ...[
                  Text('Set a 4-digit PIN (optional)'),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'PIN'),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onSaved: (v) => _pin = v,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: _prevStep, child: Text('Back')),
                      TextButton(onPressed: _nextStep, child: Text('Skip')),
                      ElevatedButton(onPressed: _nextStep, child: Text('Next')),
                    ],
                  ),
                ] else if (_step == 2) ...[
                  Text('Profile (optional)'),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Avatar URL'),
                    onSaved: (v) => _avatarUrl = v,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Bio'),
                    onSaved: (v) => _bio = v,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: _prevStep, child: Text('Back')),
                      TextButton(onPressed: _submit, child: Text('Skip')),
                      ElevatedButton(
                        onPressed: _submit,
                        child:
                            _loading
                                ? CircularProgressIndicator()
                                : Text('Finish'),
                      ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Colors.red)),
                ],
                // TODO: Add progress indicators and micro-animations
              ],
            ),
          ),
        ),
      ),
    );
  }
}
