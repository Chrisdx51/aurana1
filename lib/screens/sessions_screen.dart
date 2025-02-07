import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // ✅ Added URL Launcher

class SessionsScreen extends StatefulWidget {
  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Map<String, String>> sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  // 📌 Load saved sessions from SharedPreferences
  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedSessions = prefs.getString('sessions');

    if (savedSessions != null) {
      setState(() {
        sessions = List<Map<String, String>>.from(json.decode(savedSessions));
      });
    }
  }

  // 📌 Save sessions when a new one is added
  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessions', json.encode(sessions));
  }

  // 📌 Open a session video link directly
  Future<void> _openSessionLink(String url) async {
    if (url.isNotEmpty) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open link")),
        );
      }
    }
  }

  // 📌 Show bottom sheet for adding a new session
  void _showAddSessionDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController urlController = TextEditingController();

    showModalBottomSheet(
      isScrollControlled: true, // ✅ Allows full screen popup
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16, // ✅ Adjusts for keyboard
          ),
          child: SingleChildScrollView( // ✅ Prevents overflow
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Add New Session",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Session Title'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(labelText: 'Video URL (YouTube, etc.)'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                      setState(() {
                        sessions.add({
                          'title': titleController.text,
                          'description': descriptionController.text,
                          'videoUrl': urlController.text,
                        });
                      });
                      _saveSessions();
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 📌 Delete a session
  void _deleteSession(int index) {
    setState(() {
      sessions.removeAt(index);
    });
    _saveSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live & Recorded Sessions"), backgroundColor: Colors.blue.shade300),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Text(
                        "No sessions available. Add a new session!",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(sessions[index]['title'] ?? ""),
                            subtitle: Text(sessions[index]['description'] ?? ""),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSession(index),
                            ),
                            // ✅ Clicking the title will open the session link
                            onTap: () => _openSessionLink(sessions[index]['videoUrl'] ?? ""),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddSessionDialog,
              icon: Icon(Icons.add),
              label: Text("Add Session"),
            ),
          ],
        ),
      ),
    );
  }
}
