import 'package:flutter/material.dart';
import 'chat_screen.dart'; // Import the Chat Screen

class FriendsListScreen extends StatelessWidget {
  final List<String> friends = [
    'John Doe',
    'Jane Smith',
    'Michael Johnson',
    'Emily Davis',
  ]; // Dummy friend names

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
        backgroundColor: Colors.blue.shade300,
      ),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              child: Text(friends[index][0]),
              backgroundColor: Colors.teal.shade200,
            ),
            title: Text(friends[index]),
            trailing: Icon(Icons.chat, color: Colors.teal),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(friendName: friends[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
