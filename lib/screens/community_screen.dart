import 'package:flutter/material.dart';
import '../models/group_model.dart';

class CommunityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Community Groups')),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: communityGroups.length,
        itemBuilder: (context, index) {
          final group = communityGroups[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.group, color: Colors.purple),
              title: Text(group.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(group.description),
              trailing: Text('${group.members} members'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening ${group.name} (Coming Soon!)')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
