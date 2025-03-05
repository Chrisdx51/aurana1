import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  ChatScreen({required this.receiverId, required this.receiverName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Auto-scroll fix
  List<Map<String, dynamic>> messages = [];
  bool isTyping = false;
  bool receiverIsOnline = false; // Add receiver online status
  Timer? _typingTimer; // Typing Timer

  String lastSeen = "Loading..."; // Default text

  // Format timestamps into readable format
  String formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal(); // Convert UTC to local
    DateTime now = DateTime.now();

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"; // Show only time if today
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day - 1) {
      return "Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"; // Show "Yesterday" if yesterday
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"; // Show full date for older messages
    }
  }

  @override
  void initState() {
    super.initState();
    updateOnlineStatus(true); // ✅ Mark user as online
    fetchLastSeen();
    updateLastSeen();
    fetchMessages();
    listenForNewMessages();
    listenForUserStatus(); // ✅ Listen for user's online status
  }

  // ✅ Update Online Status in Supabase
  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').update({'is_online': isOnline}).match({'id': user.id});
      print("✅ Online status updated: $isOnline");
    } catch (error) {
      print("❌ Error updating online status: $error");
    }
  }

  Future<void> updateLastSeen() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').update({
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);
      print("✅ Last seen updated!");
    } catch (error) {
      print("❌ Error updating last seen: $error");
    }
  }

  @override
  void dispose() {
    updateOnlineStatus(false); // ✅ Mark user as offline
    updateLastSeen(); // ✅ Update last seen timestamp
    super.dispose();
  }

  Future<void> fetchLastSeen() async {
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
  }
// Fetch Messages & Ensure Profile Pictures Persist
  Future<void> fetchMessages() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("⚠️ User not logged in!");
      return;
    }

    try {
      final response = await supabase
          .from('messages')
          .select('id, sender_id, receiver_id, message, created_at, status, profiles!sender_id(name, icon)')
          .order('created_at', ascending: true);

      setState(() {
        messages = response.map((msg) {
          return {
            'id': msg['id'],
            'sender_id': msg['sender_id'],
            'receiver_id': msg['receiver_id'],
            'message': msg['message'],
            'created_at': msg['created_at'],
            'status': msg['status'],
            'profile_pic': msg['profiles']?['icon'] ?? "", // ✅ Ensure profile picture is always included
          };
        }).toList();
      });

      // ✅ Mark messages as "read"
      for (var message in response) {
        if (message['receiver_id'] == user.id && message['status'] != 'read') {
          await supabase
              .from('messages')
              .update({'status': 'read'})
              .eq('id', message['id']);
          print("✅ Message read!");
        }
      }
    } catch (error) {
      print("❌ Error fetching messages: $error");
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300), // Smooth scroll
          curve: Curves.easeOut,
        );
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
        setState(() {
          receiverIsOnline = isReceiverOnline;
        });

        print("👤 ${widget.receiverName} is now ${isReceiverOnline ? 'Online' : 'Offline'}");
      }
    });
  }

  // Listen for new messages in real-time
  // Listen for new messages in real-time
  void listenForNewMessages() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    print("🔄 Listening for real-time messages...");

    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .listen((data) async {
      if (data.isNotEmpty) {
        for (var message in data) {
          // ✅ Check if message already exists to prevent duplicate entries
          final existingIndex = messages.indexWhere((m) => m['id'] == message['id']);

          if (existingIndex == -1) {
            final profileResponse = await supabase
                .from('profiles')
                .select('icon')
                .eq('id', message['sender_id'])
                .maybeSingle();

            // ✅ Add profile picture manually
            message['profile_pic'] = profileResponse?['icon'] ?? "";

            setState(() {
              messages.add(message);
            });
          }
        }

        // ✅ Ensure scrolling happens **after UI is updated**
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        print("✅ New messages received and profile pics assigned!");
      }
    });
  }
  // Send a Message with Timestamp
  Future<void> sendMessage() async {
    final user = supabase.auth.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    try {
      await supabase.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': widget.receiverId,
        'message': _messageController.text.trim(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'sent', // ✅ Mark message as sent
      });

      _messageController.clear();
      fetchMessages(); // ✅ Refresh chat after sending
    } catch (error) {
      print("❌ Error sending message: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("Chat with ${widget.receiverName}"),
            SizedBox(width: 5),
            Icon(
              receiverIsOnline ? Icons.circle : Icons.circle_outlined,
              color: receiverIsOnline ? Colors.green : Colors.grey,
              size: 12, // ✅ Small status indicator
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (messages.isNotEmpty)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.yellow[100],
              child: Text(
                'Last received message: ${messages.last['message']}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final bool isMe = message['sender_id'] == user?.id;
                final String profilePic = message['profile_pic'] ?? "";

                return Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isMe)
                          CircleAvatar(
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : AssetImage('assets/default_avatar.png') as ImageProvider,
                            radius: 16,
                          ),
                        SizedBox(width: 8),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['message'],
                                style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 14),
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    formatTimestamp(message['created_at']),
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  SizedBox(width: 5),
                                  if (isMe)
                                    Icon(
                                      message['status'] == 'read'
                                          ? Icons.done_all // ✅✅ Read
                                          : message['status'] == 'delivered'
                                          ? Icons.done // ✅ Delivered
                                          : Icons.access_time, // ⏳ Sent
                                      size: 16,
                                      color: message['status'] == 'read'
                                          ? Colors.green
                                          : Colors.white70,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isMe)
                          CircleAvatar(
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : AssetImage('assets/default_avatar.png') as ImageProvider,
                            radius: 16,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          TypingIndicator(isTyping: isTyping), // Add Typing Indicator here
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
                    onChanged: (text) {
                      setState(() {
                        isTyping = text.isNotEmpty;
                      });

                      // Cancel previous timer if user keeps typing
                      _typingTimer?.cancel();

                      // Start a new timer to stop typing indicator after 2 seconds
                      if (text.isNotEmpty) {
                        _typingTimer = Timer(Duration(seconds: 2), () {
                          setState(() {
                            isTyping = false;
                          });
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
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
      duration: Duration(milliseconds: 300), // Smooth transition
      height: isTyping ? 30 : 0, // Keeps space even when not typing
      child: Visibility(
        visible: isTyping,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 10), // Keeps padding consistent
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2), // Smaller size
            ),
            SizedBox(width: 6), // Keeps spacing even
            Text(
              'Typing...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}