import 'package:flutter/material.dart';
import 'dart:async';
import '../chat_manager.dart';
import '../models/models.dart';
import '../ad_manager.dart' as ad_mgr;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final String peerPseudonym;
  const ChatScreen({required this.peerPseudonym, Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const MethodChannel _screenshotChannel = MethodChannel(
    'ephora/screenshot',
  );
  final ChatManager _chatManager = ChatManager();
  final ad_mgr.AdManager _adManager = ad_mgr.AdManager();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final Set<String> _viewedImages = {};
  List<Message> _messages = [];
  bool _expired = false;
  int? _expiryCountdown; // seconds remaining
  late String _sessionId;
  StreamSubscription<Message>? _msgSub;
  StreamSubscription<int>? _expirySub;
  double? _liveRssi;
  StreamSubscription<double>? _proximitySub;
  ad_mgr.AdBanner? _adBanner;
  bool _dissolving = false;
  List<String> _emojis = [
    '😀',
    '😂',
    '😍',
    '🥳',
    '😎',
    '😭',
    '😡',
    '🥺',
    '👍',
    '👻',
    '💖',
    '🔥',
    '🌊',
    '✨',
    '🎉',
    '🤙',
    '🙌',
    '😏',
    '😳',
    '😬',
    '🤡',
  ];

  // Screenshot protection prompt (placeholder)
  bool _showScreenshotWarning = false;
  // This would be triggered by platform channel in a real app
  void _onScreenshotDetected() {
    setState(() => _showScreenshotWarning = true);
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) setState(() => _showScreenshotWarning = false);
    });
  }

  void _triggerDissolve() async {
    setState(() => _dissolving = true);
    await Future.delayed(Duration(milliseconds: 900));
    setState(() => _messages.clear());
  }

  void _showEmojiPicker() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            children:
                _emojis
                    .map(
                      (emoji) => InkWell(
                        onTap: () {
                          _controller.text += emoji;
                          Navigator.pop(context);
                        },
                        child: Center(
                          child: Text(emoji, style: TextStyle(fontSize: 28)),
                        ),
                      ),
                    )
                    .toList(),
          ),
    );
  }

  void _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null && !_expired) {
      final msg = Message(
        senderPseudonym: 'Me',
        content: picked.path,
        timestamp: DateTime.now(),
        type: MessageType.image,
      );
      _chatManager.sendMessage(_sessionId, msg);
    }
  }

  Widget _buildImageMessage(Message msg) {
    final viewed = _viewedImages.contains(msg.content);
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewedImages.add(msg.content);
        });
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColorFiltered(
              colorFilter:
                  viewed
                      ? ColorFilter.mode(
                        Colors.black.withOpacity(0.7),
                        BlendMode.srcATop,
                      )
                      : ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.file(
                File(msg.content),
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (viewed)
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  'Viewed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sessionId = widget.peerPseudonym;
    _chatManager.startChatSession(User(pseudonym: widget.peerPseudonym));
    _messages = _chatManager.getMessages(_sessionId);
    _msgSub = _chatManager.onMessageReceived(_sessionId).listen((msg) {
      setState(() {
        _messages.add(msg);
      });
    });
    _expirySub = _chatManager.onExpiryCountdown(_sessionId).listen((count) {
      setState(() {
        _expiryCountdown = count;
        if (count <= 0 && !_dissolving) {
          _expired = true;
          _triggerDissolve();
        }
      });
    });
    // Subscribe to live proximity for pulse icon
    _proximitySub = BleManager()
        .onProximityChanged(widget.peerPseudonym)
        .listen((rssi) {
          setState(() {
            _liveRssi = rssi;
          });
        });
    // Fetch ad banner once for now (could rotate/fetch new ad later)
    _adManager.fetchBannerAd().then((ad) {
      setState(() {
        _adBanner = ad;
      });
    });
    _screenshotChannel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenshot') {
        _onScreenshotDetected();
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _expirySub?.cancel();
    _proximitySub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _proximityColor(double? rssi) {
    if (rssi == null) return Colors.grey;
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.yellow;
    return Colors.red;
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty || _expired) return;
    final msg = Message(
      senderPseudonym: 'Me',
      content: _controller.text.trim(),
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
    _chatManager.sendMessage(_sessionId, msg);
    _controller.clear();
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              Text(widget.peerPseudonym),
              SizedBox(width: 12),
              AnimatedContainer(
                duration: Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width:
                    _liveRssi != null
                        ? (24 +
                            (20 *
                                (1 - ((_liveRssi!.clamp(-90, -40) + 90) / 50))))
                        : 24,
                height:
                    _liveRssi != null
                        ? (24 +
                            (20 *
                                (1 - ((_liveRssi!.clamp(-90, -40) + 90) / 50))))
                        : 24,
                child: Icon(Icons.favorite, color: _proximityColor(_liveRssi)),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_expired)
                  Container(
                    width: double.infinity,
                    color: Colors.red,
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Chat expired due to distance—messages deleted.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_expiryCountdown != null && !_expired)
                  Container(
                    width: double.infinity,
                    color: Colors.orange,
                    padding: EdgeInsets.all(8),
                    child: Text(
                      '⚠️ Auto-delete in $_expiryCountdown s… RUN BACK!',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length + (_messages.length ~/ 5),
                    itemBuilder: (context, index) {
                      int adInterval = 5;
                      int numAdsBefore = index ~/ (adInterval + 1);
                      int msgIndex =
                          _messages.length - 1 - (index - numAdsBefore);
                      if ((index + 1) % (adInterval + 1) == 0 &&
                          _adBanner != null) {
                        // Insert ad banner after every 5 messages
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: GestureDetector(
                            onTap: () async {
                              if (_adBanner != null) {
                                final url = Uri.parse(_adBanner!.linkUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              }
                            },
                            child: Container(
                              height: 60,
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
                        );
                      }
                      if (msgIndex < 0) return SizedBox.shrink();
                      final msg = _messages[msgIndex];
                      return Align(
                        alignment:
                            msg.senderPseudonym == 'Me'
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: AnimatedOpacity(
                          opacity: _dissolving ? 0.0 : 1.0,
                          duration: Duration(milliseconds: 900),
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return _dissolving
                                  ? LinearGradient(
                                    colors: [
                                      Colors.purpleAccent,
                                      Colors.cyanAccent,
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ).createShader(bounds)
                                  : LinearGradient(
                                    colors: [Colors.white, Colors.white],
                                  ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcATop,
                            child:
                                msg.type == MessageType.image
                                    ? _buildImageMessage(msg)
                                    : Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 12,
                                      ),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            msg.senderPseudonym == 'Me'
                                                ? Colors.blue[200]
                                                : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(msg.content),
                                          SizedBox(height: 4),
                                          Text(
                                            '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  color: Colors.grey[100],
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.emoji_emotions_outlined),
                        onPressed: _showEmojiPicker,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type a message…',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.image_outlined),
                        onPressed: _pickImage,
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showScreenshotWarning)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.red,
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Screenshots are discouraged for privacy.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            if (_expired)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, color: Colors.white, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No cap, your chat expired.',
                          style: TextStyle(color: Colors.white, fontSize: 22),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Wave again when nearby'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
