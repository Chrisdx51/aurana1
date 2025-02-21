import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> messages = [];

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    final response = await supabase.from('messages').select('sender_id, receiver_id, message, created_at').order('created_at', ascending: false);

    if (response.isNotEmpty) {
      setState(() {
        messages = response;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messages')),
      body: messages.isEmpty
          ? Center(child: Text('No messages yet'))
          : ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("From ${messages[index]['sender_id']}"),
            subtitle: Text(messages[index]['message']),
            trailing: Text(messages[index]['created_at']),
          );
        },
      ),
    );
  }
}
