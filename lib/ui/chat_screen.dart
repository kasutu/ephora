import 'package:flutter/material.dart';
import 'dart:async';
import '../chat_manager.dart';
import '../models/models.dart';

class ChatScreen extends StatefulWidget {
  final String peerPseudonym;
  const ChatScreen({required this.peerPseudonym, Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatManager _chatManager = ChatManager();
  final TextEditingController _controller = TextEditingController();
  List<Message> _messages = [];
  bool _expired = false;
  int? _expiryCountdown; // seconds remaining
  late String _sessionId;
  StreamSubscription<Message>? _msgSub;
  StreamSubscription<int>? _expirySub;

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
        if (count <= 0) _expired = true;
      });
    });
    // Simulate proximity monitoring (for demo, triggers expiry after 5s)
    Future.delayed(Duration(seconds: 5), () {
      _chatManager.monitorProximity(_sessionId, rssi: -85); // out of range
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _expirySub?.cancel();
    _controller.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.peerPseudonym),
            SizedBox(width: 12),
            Icon(Icons.wifi_tethering, color: Colors.green),
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
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[_messages.length - 1 - index];
                    return Align(
                      alignment:
                          msg.senderPseudonym == 'Me'
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                      onPressed: () {}, // TODO: Emoji picker
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
                      onPressed: () {}, // TODO: Image picker
                    ),
                    IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
                  ],
                ),
              ),
            ],
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
    );
  }
}
