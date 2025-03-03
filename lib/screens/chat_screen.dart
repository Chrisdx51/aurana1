import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    fetchMessages();
    listenForNewMessages();
  }

  // ✅ Fetch Messages from Supabase
  Future<void> fetchMessages() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("⚠️ User not logged in!");
      return;
    }

    try {
      final response = await supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.${user.id},receiver_id.eq.${widget.receiverId}), and(sender_id.eq.${widget.receiverId},receiver_id.eq.${user.id})')
          .order('created_at', ascending: true);

      setState(() {
        messages = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      print("❌ Error fetching messages: $error");
    }
  }

  // ✅ Listen for new messages in real-time (Fixed Supabase Stream API)
  // ✅ Listen for new messages in real-time
  void listenForNewMessages() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id) // ✅ Only listen for messages sent to this user
        .order('created_at', ascending: true)
        .listen((List<Map<String, dynamic>> newMessages) {
      if (newMessages.isNotEmpty) {
        setState(() {
          messages.addAll(newMessages);
        });
      }
    });

    print("🔄 Listening for new messages...");
  }


  // ✅ Send a Message
  Future<void> sendMessage() async {
    final user = supabase.auth.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    try {
      await supabase.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': widget.receiverId,
        'message': _messageController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
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
      appBar: AppBar(title: Text("Chat with ${widget.receiverName}")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final bool isMe = message['sender_id'] == user?.id;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message['message'],
                      style: TextStyle(color: isMe ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
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