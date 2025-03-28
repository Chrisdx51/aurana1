import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
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
  bool isReceiverTyping = false;


  DateTime? lastTypedTime;


  @override
  void initState() {
    super.initState();
    supabaseService.setActiveChat(widget.receiverId);


    // When the widget first builds, run _initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();

      // ✅ Listen to keyboard open/close
      WidgetsBinding.instance.addObserver(
        LifecycleEventHandler(
          resumeCallBack: () async => _scrollToBottom(),
        ),
      );
    });

    _subscribeToMessages(supabase.auth.currentUser?.id ?? '', widget.receiverId);
  }


  @override
  void didUpdateWidget(covariant MessageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receiverId != widget.receiverId) {
      // Reset everything when the receiver changes
      _initialize();
    }
  }

  void _subscribeToMessages(String userId, String receiverId) {
    supabase.channel('messages_channel')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        column: 'receiver_id',
        value: userId,
        type: PostgresChangeFilterType.eq,
      ),
      callback: (payload) {
        _fetchMessages();
      },
    )
        .subscribe();
  }

  Future<void> _initialize() async {
    setState(() {
      isLoading = true;
      messages = [];
    });

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    isFriend = await supabaseService.checkIfFriends(currentUserId, widget.receiverId);
    hasReplied = await supabaseService.hasReceiverReplied(currentUserId, widget.receiverId);
    remainingMessages = await supabaseService.nonFriendMessageCountToday(currentUserId, widget.receiverId);

    final fetchedMessages = await supabaseService.fetchMessages(currentUserId, widget.receiverId);
    for (var msg in fetchedMessages) {
      final profile = await supabaseService.getUserProfile(msg['sender_id']);
      msg['avatar'] = profile?.avatar ?? '';
    }

    setState(() {
      messages = fetchedMessages;
      isLoading = false;
    });

    _scrollToBottom();
    await _markMessagesAsSeen();

    firstMessage = messages.isEmpty;
    _subscribeToTypingStatus();

    if (firstMessage) {
      Future.delayed(Duration(milliseconds: 500), () => _showFirstMessagePopup());
    }
  }

  Future<void> _fetchMessages() async {
    final currentUserId = supabase.auth.currentUser?.id;
    final receiverId = widget.receiverId;

    if (currentUserId == null || receiverId.isEmpty) return;

    final response = await supabase
        .from('messages')
        .select('*')
        .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$currentUserId)')
        .order('created_at', ascending: true);


    for (var msg in response) {
      if (msg['receiver_id'] == currentUserId && msg['delivered'] == false) {
        await supabase.from('messages').update({'delivered': true}).eq('id', msg['id']);
      }

      final profile = await supabaseService.getUserProfile(msg['sender_id']);
      msg['avatar'] = profile?.avatar ?? '';
    }

    setState(() => messages = response);
    _scrollToBottom();
  }

  Future<void> _markMessagesAsSeen() async {
    final currentUserId = supabase.auth.currentUser?.id;
    final senderId = widget.receiverId;

    if (currentUserId == null || senderId.isEmpty) return;

    await supabase
        .from('messages')
        .update({'seen': true})
        .eq('receiver_id', currentUserId)
        .eq('sender_id', senderId);
  }


  Future<void> _sendMessage() async {
    final currentUserId = supabase.auth.currentUser?.id;
    final messageText = _messageController.text.trim();

    if (currentUserId == null || messageText.isEmpty) return;

    remainingMessages = await supabaseService.nonFriendMessageCountToday(currentUserId, widget.receiverId);

    if (!isFriend && !hasReplied) {
      if (remainingMessages >= 1) {
        _showMessage("🚫 You can only send ONE message until they reply or become friends 🌌");
        return;
      }
    }

    bool success = await supabaseService.sendMessage(
      senderId: currentUserId,
      receiverId: widget.receiverId,
      message: messageText,
    );

    if (success) {
      _messageController.clear();
      await _fetchMessages();
      if (!isFriend && !hasReplied) {
        setState(() => remainingMessages++);
      }
      _scrollToBottom();
    } else {
      _showMessage("❌ Message failed to send.");
    }
  }

  Future<void> _sendImageMessage() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);

    // 🖼️ Step 1: Ask for confirmation before sending
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Send Image?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(file, height: 200),
            SizedBox(height: 10),
            Text("Do you want to send this image?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Send"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 🗂️ Step 2: Upload and send if confirmed
    final ext = path.extension(picked.path);
    final storagePath = 'message_media/${userId}_${DateTime.now().millisecondsSinceEpoch}$ext';

    await supabase.storage.from('post_media').upload(storagePath, file);
    final publicUrl = supabase.storage.from('post_media').getPublicUrl(storagePath);

    bool success = await supabaseService.sendMessage(
      senderId: userId,
      receiverId: widget.receiverId,
      message: publicUrl,
    );

    if (success) {
      await _fetchMessages();
      _scrollToBottom();
    }
  }


  void _subscribeToTypingStatus() {
    final myId = supabase.auth.currentUser?.id;
    final theirId = widget.receiverId;

    if (myId == null || theirId.isEmpty) return;

    supabase.channel('typing_channel_${myId}_$theirId')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'typing_status',
      filter: PostgresChangeFilter(
        column: 'receiver_id',
        value: myId,
        type: PostgresChangeFilterType.eq,
      ),
      callback: (payload) {
        final newTyping = payload.newRecord;
        final isTyping = newTyping['is_typing'] ?? false;

        if (mounted) {
          setState(() {
            isReceiverTyping = isTyping;
          });
        }
      },
    )
        .subscribe();
  }

  void _showFirstMessagePopup() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.black.withOpacity(0.85),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.tealAccent, size: 32),
              SizedBox(height: 16),
              Text('New Soul Connection', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('You are reaching out to a new soul.\nSend a message filled with light ✨',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
                child: Text('Send with Light 🌟', style: TextStyle(color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.black87));
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

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final bool isImage = msg['message'].toString().startsWith('http');
    final avatarUrl = msg['avatar'] ?? '';

    final avatarWidget = CircleAvatar(
      radius: 16,
      backgroundImage: avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : AssetImage('assets/images/default_avatar.png') as ImageProvider,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) avatarWidget,
          if (!isMe) SizedBox(width: 8),

          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                constraints: BoxConstraints(maxWidth: 250),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isImage
                    ? GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(child: Image.network(msg['message'])),
                  ),
                  child: Image.network(msg['message'], height: 150),
                )
                    : Text(
                  msg['message'],
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(msg['created_at'] ?? ""),
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                  if (isMe && msg['seen'] == true) ...[
                    SizedBox(width: 6),
                    Icon(Icons.crisis_alert, color: Colors.deepPurpleAccent, size: 14), // 🔮 Seen
                  ] else if (isMe && msg['delivered'] == true) ...[
                    SizedBox(width: 6),
                    Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14), // ✨ Delivered
                  ],
                ],
              ),
            ],
          ),

          if (isMe) SizedBox(width: 8),
          if (isMe) avatarWidget,
        ],
      ),
    );
  }



  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image, color: Colors.white),
            onPressed: _sendImageMessage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (text) => _updateTypingStatus(text.isNotEmpty),

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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, shape: CircleBorder()),
            child: Icon(Icons.send, color: Colors.black),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return "";
    final DateTime time = DateTime.parse(isoTime).toLocal();
    final DateTime now = DateTime.now();

    final bool isToday = now.year == time.year &&
        now.month == time.month &&
        now.day == time.day;

    if (isToday) {
      // Only show time like "14:05"
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    } else {
      // Show full date and time like "Mar 25, 14:05"
      return "${_formatDate(time)} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  String _formatDate(DateTime date) {
    // This gives "Mar 25" format
    final months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[date.month - 1]} ${date.day}";
  }


  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ Important for auto-scroll
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
          Positioned.fill(child: Image.asset('assets/images/misc2.png', fit: BoxFit.cover)),
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
              if (isReceiverTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${widget.receiverName} is typing...",
                      style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              _buildMessageInput(),
            ],
          ),
        ],
      ),
    );
  }

  Timer? _typingTimer;

  Future<void> _updateTypingStatus(bool isTyping) async {
    final userId = supabase.auth.currentUser?.id;
    final receiverId = widget.receiverId;
    if (userId == null) return;

    // Cancel any existing timer
    _typingTimer?.cancel();

    // If typing, update status and start a timer to turn it off
    if (isTyping) {
      await supabase.from('typing_status').upsert({
        'user_id': userId,
        'receiver_id': receiverId,
        'is_typing': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,receiver_id');

      // Start a timer to clear typing after 3 seconds of no activity
      _typingTimer = Timer(Duration(seconds: 3), () async {
        await supabase.from('typing_status').upsert({
          'user_id': userId,
          'receiver_id': receiverId,
          'is_typing': false,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,receiver_id');
      });
    } else {
      // If empty or cleared immediately
      await supabase.from('typing_status').upsert({
        'user_id': userId,
        'receiver_id': receiverId,
        'is_typing': false,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,receiver_id');
    }
  }


  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Message"),
        content: Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(child: Text("Cancel"), onPressed: () => Navigator.pop(context, false)),
          TextButton(child: Text("Delete"), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
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

  @override
  void dispose() {
    _typingTimer?.cancel(); // ✅ Stop the typing timer
    _messageController.dispose(); // ✅ Clean up controller
    _scrollController.dispose(); // ✅ Clean up scroll
    super.dispose();
    supabaseService.clearActiveChat();

  }

}
class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function()? resumeCallBack;

  LifecycleEventHandler({this.resumeCallBack});

  @override
  void didChangeMetrics() {
    // This runs when keyboard opens or closes
    if (resumeCallBack != null) {
      resumeCallBack!();
    }
  }
}
