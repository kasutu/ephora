import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import '../auth_manager.dart';

// Onboarding screen: signup, PIN, profile
class OnboardingScreen extends StatefulWidget {
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _pseudonymController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _bioController = TextEditingController();
  String? _pseudonym;
  String? _password;
  String? _pin;
  String? _avatarUrl;
  String? _bio;
  bool _loading = false;
  String? _error;

  late AnimationController _splashController;
  late Animation<double> _splashAnim;

  // Pseudonym generator
  final List<String> _pseudonymAdjectives = [
    'Cosmic',
    'Ghosted',
    'Vibing',
    'Chill',
    'Neon',
    'Retro',
    'Dreamy',
    'Hype',
    'Zen',
    'Lowkey',
    'Wavy',
    'Glitchy',
    'Night',
    'Star',
    'Pixel',
    'Nova',
    'Lofi',
    'Moody',
    'Sunny',
    'Frosty',
  ];
  final List<String> _pseudonymNouns = [
    'Taco',
    'U',
    'Star',
    'Owl',
    'Cat',
    'Vapor',
    'Wave',
    'Fox',
    'Bean',
    'Ghost',
    'Vibe',
    'Sloth',
    'Duck',
    'Frog',
    'Moon',
    'Glow',
    'Cloud',
    'Wolf',
    'Bear',
    'Peach',
  ];
  String _generatePseudonym() {
    final adj = (_pseudonymAdjectives..shuffle()).first;
    final noun = (_pseudonymNouns..shuffle()).first;
    final num =
        (10 + (90 * (new DateTime.now().millisecondsSinceEpoch % 1000) / 1000))
            .toInt();
    return '$adj$noun$num';
  }

  // Mood badges
  final List<String> _moods = [
    '✨Vibing✨',
    '🌙Night Owl',
    '🔥On Fire',
    '🥶Chill',
    '😎Lowkey',
    '🤙Down',
    '🥳Hyped',
    '💤Sleepy',
    '🤓Study',
    '🎮Gaming',
  ];
  String? _selectedMood;

  Future<bool> _isPseudonymTaken(String pseudonym) async {
    try {
      await AuthManager().signUp(pseudonym, 'dummyPassword');
      // If no error, remove dummy user
      // (In real app, use a proper check endpoint)
      return false;
    } catch (e) {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    _splashAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _splashController.dispose();
    _pseudonymController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _avatarUrlController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_step == 0) {
      if (!_formKey.currentState!.validate()) return;
      _formKey.currentState!.save();
      setState(() {
        _loading = true;
        _error = null;
      });
      if (await _isPseudonymTaken(_pseudonym!)) {
        setState(() {
          _error = 'Pseudonym already taken. Please choose another.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _loading = false;
      });
    }
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
        avatarUrl: _avatarUrl,
        bio:
            _bio != null && _selectedMood != null
                ? '$_bio $_selectedMood'
                : _bio,
      );
      // Navigate to discovery screen
      Navigator.of(context).pushReplacementNamed('/discover');
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
                // Step progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            i <= _step ? Colors.blueAccent : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (_step == 0) ...[
                  Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  // Animated BLE wave splash
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: ScaleTransition(
                      scale: _splashAnim,
                      child: Icon(
                        Icons.waves,
                        color: Colors.blueAccent,
                        size: 64,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pseudonymController,
                          decoration: InputDecoration(labelText: 'Pseudonym'),
                          onSaved: (v) => _pseudonym = v,
                          validator:
                              (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.casino),
                        tooltip: 'Suggest pseudonym',
                        onPressed: () {
                          setState(() {
                            _pseudonym = _generatePseudonym();
                            _pseudonymController.text = _pseudonym!;
                          });
                        },
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _passwordController,
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
                    controller: _pinController,
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
                    controller: _avatarUrlController,
                    decoration: InputDecoration(labelText: 'Avatar URL'),
                    onSaved: (v) => _avatarUrl = v,
                  ),
                  TextFormField(
                    controller: _bioController,
                    decoration: InputDecoration(labelText: 'Bio'),
                    onSaved: (v) => _bio = v,
                  ),
                  SizedBox(height: 8),
                  Text('Mood Badge (optional):'),
                  Wrap(
                    spacing: 8,
                    children:
                        _moods
                            .map(
                              (mood) => ChoiceChip(
                                label: Text(mood),
                                selected: _selectedMood == mood,
                                onSelected: (selected) {
                                  setState(
                                    () =>
                                        _selectedMood = selected ? mood : null,
                                  );
                                },
                              ),
                            )
                            .toList(),
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
                // Progress message
                if (_step == 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Slay, 90% onboarded!',
                      style: TextStyle(color: Colors.purpleAccent),
                    ),
                  ),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: LinearProgressIndicator(),
                  ),
                // TODO: Add progress indicators and micro-animations
              ],
            ),
          ),
        ),
      ),
    );
  }
}
