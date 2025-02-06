import 'package:flutter/material.dart';

class SpiritualToolsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tools = [
    {'name': 'Tarot Reading', 'icon': Icons.style},
    {'name': 'Moon Cycle Tracking', 'icon': Icons.nightlight_round},
    {'name': 'Affirmations', 'icon': Icons.format_quote},
    {'name': 'Guided Breathing', 'icon': Icons.self_improvement},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spiritual Tools')),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(tool['icon'], color: Colors.purple),
              title: Text(tool['name'], style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${tool['name']} - Coming Soon!')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
