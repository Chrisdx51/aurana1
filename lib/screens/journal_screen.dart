import 'package:flutter/material.dart';
import '../models/journal_entry.dart';

class JournalScreen extends StatefulWidget {
  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  void _addJournalEntry() {
    String title = _titleController.text.trim();
    String content = _contentController.text.trim();

    if (title.isNotEmpty && content.isNotEmpty) {
      setState(() {
        journalEntries.insert(0, JournalEntry(
          title: title,
          content: content,
          dateTime: DateTime.now().toString(),
        ));
        _titleController.clear();
        _contentController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Journal entry saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Personal Growth Journal')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: journalEntries.length,
              itemBuilder: (context, index) {
                final entry = journalEntries[index];
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(entry.title, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5),
                        Text(entry.content),
                        SizedBox(height: 5),
                        Text(entry.dateTime, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Entry Title'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(labelText: 'Write your thoughts...'),
                  maxLines: 4,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addJournalEntry,
                  child: Text('Save Entry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
