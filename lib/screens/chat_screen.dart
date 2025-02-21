import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> chats = [];

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    final response = await supabase.from('chats').select('*');

    if (response.isNotEmpty) {
      setState(() {
        chats = response;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chats')),
      body: chats.isEmpty
          ? Center(child: Text('No chats available'))
          : ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("Chat between ${chats[index]['user_one']} and ${chats[index]['user_two']}"),
          );
        },
      ),
    );
  }
}
