import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../services/supabase_service.dart';
import '../widgets/banner_ad_widget.dart';

class MessageScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const MessageScreen({
    required this.receiverId,
    required this.receiverName,
  });

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final SupabaseService supabaseService = SupabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isFriend = false;
  int remainingMessages = 10;
  bool hasReplied = false;
  bool firstMessage = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    _subscribeToMessages(supabase.auth.currentUser?.id ?? '', widget.receiverId);
  }

  // ✅ Real-time updates!
  void _subscribeToMessages(String userId, String receiverId) {
    supabase.channel('messages_channel')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        column: 'receiver_id',
        value: userId,
        type: PostgresChangeFilterType.eq, // ✅ THIS is required!
      ),
      callback: (payload) {
        print('📩 New message payload: ${payload.newRecord}');
        _fetchMessages(); // Refresh messages
      },
    )
        .subscribe();
  }




  Future<void> _initialize() async {
    setState(() => isLoading = true);

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    isFriend = await supabaseService.checkIfFriends(currentUserId, widget.receiverId);
    hasReplied = await supabaseService.hasReceiverReplied(currentUserId, widget.receiverId);
    remainingMessages = await supabaseService.nonFriendMessageCountToday(currentUserId, widget.receiverId);

    await _fetchMessages();

    firstMessage = messages.isEmpty;
    if (firstMessage) {
      Future.delayed(Duration(milliseconds: 500), () => _showFirstMessagePopup());
    }

    setState(() => isLoading = false);
  }

  Future<void> _fetchMessages() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final fetchedMessages = await supabaseService.fetchMessages(currentUserId, widget.receiverId);
    setState(() => messages = fetchedMessages);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final currentUserId = supabase.auth.currentUser?.id;
    final messageText = _messageController.text.trim();

    if (currentUserId == null || messageText.isEmpty) return;

    // 🔥 Get the remaining message count BEFORE sending
    remainingMessages = await supabaseService.nonFriendMessageCountToday(currentUserId, widget.receiverId);

    // 🚫 Block if they're not friends & no reply yet & already sent 1 message
    if (!isFriend && !hasReplied) {
      if (remainingMessages >= 1) {
        _showMessage("🚫 You can only send ONE message until they reply or become friends 🌌");
        return;
      }
    }

    // ✅ Send the message
    bool success = await supabaseService.sendMessage(
      senderId: currentUserId,
      receiverId: widget.receiverId,
      message: messageText,
    );

    if (success) {
      _messageController.clear();
      await _fetchMessages();

      // ⚠️ Increase the remaining message count manually (optional)
      if (!isFriend && !hasReplied) {
        setState(() => remainingMessages++);
      }

      _scrollToBottom();
    } else {
      _showMessage("❌ Message failed to send.");
    }
  }


  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _buildDeleteDialog(),
    );

    if (confirm != true) return;

    final success = await supabaseService.deleteMessage(messageId);
    if (success) {
      _showMessage("✅ Message deleted.");
      await _fetchMessages();
    } else {
      _showMessage("❌ Failed to delete message.");
    }
  }

  // ✅ Spiritual popup (clean and small)
  void _showFirstMessagePopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
            SizedBox(width: 8),
            Text('New Soul Connection', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You are reaching out to a new soul ✨',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Speak with kindness & purpose.\nThis is a sacred space 💜',
              style: TextStyle(color: Colors.amberAccent, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Send with Light 🌟', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade900, Colors.purple.shade600, Colors.amber.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/misc2.png', fit: BoxFit.cover),
          ),
          Column(
            children: [
              BannerAdWidget(),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == currentUserId;
                    return GestureDetector(
                      onLongPress: () {
                        if (isMe) _deleteMessage(msg['id']);
                      },
                      child: _buildMessageBubble(msg, isMe),
                    );
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            constraints: BoxConstraints(maxWidth: 250),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.amberAccent.withOpacity(0.9)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg['message'],
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          SizedBox(height: 4),
          Text(
            _formatTime(msg['created_at'] ?? ""),
            style: TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, -1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type a soul message...",
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              shape: CircleBorder(),
              padding: EdgeInsets.all(12),
            ),
            child: Icon(Icons.send, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.deepPurple.shade900.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.redAccent, size: 32),
            SizedBox(height: 12),
            Text(
              'Delete Message?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Are you sure you want to delete this message?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Text("Cancel", style: TextStyle(color: Colors.white70)),
                  onPressed: () => Navigator.pop(context, false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: Text("Delete", style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return "";
    DateTime time = DateTime.parse(isoTime).toLocal();
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
