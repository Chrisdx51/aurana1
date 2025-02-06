import 'package:flutter/material.dart';

class SessionsScreen extends StatelessWidget {
  final List<Map<String, String>> sessions = [
    {'title': 'Live Meditation Session', 'time': 'Today at 6:00 PM'},
    {'title': 'Manifestation Q&A', 'time': 'Tomorrow at 8:00 PM'},
    {'title': 'Breathwork Workshop', 'time': 'Friday at 7:30 PM'},
    {'title': 'Recorded: Chakra Healing', 'time': 'Available Anytime'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live & Recorded Sessions')),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.play_circle_fill, color: Colors.purple),
              title: Text(session['title']!, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(session['time']!),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${session['title']} - Coming Soon!')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
