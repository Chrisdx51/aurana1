import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../services/encryption_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  ChatScreen({required this.receiverId, required this.receiverName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isTyping = false;
  bool receiverIsOnline = false;
  String lastSeen = 'Loading...';
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    updateOnlineStatus(true);
    fetchLastSeen();
    listenForUserStatus();
    fetchMessages();
    listenForNewMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    updateOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await updateOnlineStatus(true);
    } else {
      await updateOnlineStatus(false);
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profiles').update({'is_online': isOnline}).eq('id', user.id);
  }

  Future<void> updateLastSeen() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profiles').update({
      'last_seen': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);
  }

  void fetchLastSeen() async {
    Timer.periodic(Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final response = await supabase
            .from('profiles')
            .select('last_seen')
            .eq('id', widget.receiverId)
            .maybeSingle();

        if (response != null && response['last_seen'] != null) {
          DateTime lastSeenTime = DateTime.parse(response['last_seen']).toLocal();
          setState(() {
            lastSeen = "Last seen: ${formatTimestamp(lastSeenTime.toIso8601String())}";
          });
        } else {
          setState(() {
            lastSeen = "Last seen: Unknown";
          });
        }
      } catch (error) {
        print("❌ Error fetching last seen: $error");
      }
    });
  }

  void listenForUserStatus() {
    supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.receiverId)
        .listen((data) {
      if (data.isNotEmpty) {
        bool isReceiverOnline = data.first['is_online'] ?? false;
        bool isReceiverTyping = data.first['is_typing'] ?? false;

        setState(() {
          receiverIsOnline = isReceiverOnline;
          isTyping = isReceiverTyping;
        });
      }
    });
  }

  Future<void> fetchMessages() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final messagesSent = await supabase
          .from('messages')
          .select('*')
          .eq('sender_id', user.id)
          .eq('receiver_id', widget.receiverId)
          .order('created_at', ascending: true);

      final messagesReceived = await supabase
          .from('messages')
          .select('*')
          .eq('sender_id', widget.receiverId)
          .eq('receiver_id', user.id)
          .order('created_at', ascending: true);

      final combinedMessages = [...messagesSent, ...messagesReceived];

      combinedMessages.sort((a, b) =>
          DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));

      setState(() {
        messages = combinedMessages;
      });

      _scrollToBottom();
    } catch (error) {
      print('❌ Error fetching messages: $error');
    }
  }

  void listenForNewMessages() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .listen((data) {
      if (!mounted) return;

      final newMessages = data.where((message) {
        final senderId = message['sender_id'];
        final receiverId = message['receiver_id'];

        return (senderId == widget.receiverId && receiverId == user.id) ||
            (senderId == user.id && receiverId == widget.receiverId);
      }).toList();

      if (newMessages.isNotEmpty) {
        setState(() {
          for (var msg in newMessages) {
            if (!messages.any((m) => m['id'] == msg['id'])) {
              messages.add(msg);
            }
          }

          messages.sort((a, b) =>
              DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
        });

        _scrollToBottom();
      }
    });
  }

  Future<void> sendMessage() async {
    final user = supabase.auth.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    try {
      final encryptedMessage =
      EncryptionService.encryptMessage(_messageController.text.trim());

      await supabase.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': widget.receiverId,
        'message': encryptedMessage,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'sent',
      });

      _messageController.clear();
      fetchMessages();
    } catch (error) {
      print("❌ Error sending message: $error");
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.receiverName),
            SizedBox(width: 6),
            Icon(
              receiverIsOnline ? Icons.circle : Icons.circle_outlined,
              color: receiverIsOnline ? Colors.green : Colors.grey,
              size: 12,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(child: Text(lastSeen, style: TextStyle(fontSize: 12))),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['sender_id'] == user?.id;
                final decryptedMsg = EncryptionService.decryptMessage(msg['message']);

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          decryptedMsg,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formatTimestamp(msg['created_at']),
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          TypingIndicator(isTyping: isTyping),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) async {
                      final userId = supabase.auth.currentUser?.id;

                      setState(() {
                        isTyping = text.isNotEmpty;
                      });

                      if (userId != null) {
                        await supabase.from('profiles').update({
                          'is_typing': text.isNotEmpty
                        }).eq('id', userId);
                      }

                      _typingTimer?.cancel();
                      if (text.isNotEmpty) {
                        _typingTimer = Timer(Duration(seconds: 2), () async {
                          setState(() => isTyping = false);
                          if (userId != null) {
                            await supabase.from('profiles').update({
                              'is_typing': false
                            }).eq('id', userId);
                          }
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  final bool isTyping;

  const TypingIndicator({required this.isTyping});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: isTyping ? 30 : 0,
      child: isTyping
          ? Row(
        children: [
          SizedBox(width: 12),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 6),
          Text('Typing...', style: TextStyle(fontSize: 12)),
        ],
      )
          : SizedBox.shrink(),
    );
  }
}
