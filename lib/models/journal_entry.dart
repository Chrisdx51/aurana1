import 'package:flutter/material.dart';
import 'dart:io';  // Import the dart:io library

class JournalEntry {
  final String title;
  final String content;
  final String dateTime;
  final String mood; // Required mood field
  final String? imagePath; // Add image path
  final List<String> tags; // Add tags

  JournalEntry({
    required this.title,
    required this.content,
    required this.dateTime,
    required this.mood,
    this.imagePath, // Initialize image path
    this.tags = const [], // Initialize tags
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'dateTime': dateTime,
        'mood': mood,
        'imagePath': imagePath,
        'tags': tags,
      };

  static JournalEntry fromJson(Map<String, dynamic> json) => JournalEntry(
        title: json['title'],
        content: json['content'],
        dateTime: json['dateTime'],
        mood: json['mood'],
        imagePath: json['imagePath'],
        tags: List<String>.from(json['tags']),
      );
}

// Example function to add a new journal entry
void addJournalEntry(List<JournalEntry> journalEntries, String content, String mood, String? imagePath, List<String> tags) {
  journalEntries.insert(
    0,
    JournalEntry(
      title: "Entry",
      content: content,
      dateTime: DateTime.now().toString(),
      mood: mood,
      imagePath: imagePath,
      tags: tags,
    ),
  );
}

class JournalEntryForm extends StatefulWidget {
  @override
  _JournalEntryFormState createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends State<JournalEntryForm> {
  String selectedMood = "Happy";
  final TextEditingController contentController = TextEditingController();
  File? selectedImage;
  final List<String> tags = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          value: selectedMood,
          items: ["Happy", "Sad", "Neutral", "Excited", "Calm"]
              .map((mood) => DropdownMenuItem(
                    value: mood,
                    child: Text(mood),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedMood = value!;
            });
          },
        ),
        TextField(
          controller: contentController,
          decoration: InputDecoration(labelText: 'Content'),
        ),
        ElevatedButton(
          onPressed: () {
            // Assuming you have a list of journal entries
            List<JournalEntry> journalEntries = [];
            addJournalEntry(
                journalEntries, contentController.text, selectedMood, selectedImage?.path, tags);
          },
          child: Text('Add Journal Entry'),
        ),
      ],
    );
  }
}