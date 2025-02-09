import 'package:flutter/material.dart';

class JournalEntry {
  final String title;
  final String content;
  final String dateTime;
  final String mood; // ✅ Required mood field

  JournalEntry({
    required this.title,
    required this.content,
    required this.dateTime,
    required this.mood, // ✅ Add mood here
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'dateTime': dateTime,
        'mood': mood,
      };

  static JournalEntry fromJson(Map<String, dynamic> json) => JournalEntry(
        title: json['title'],
        content: json['content'],
        dateTime: json['dateTime'],
        mood: json['mood'], // ✅ Parse mood from JSON
      );
}

// Example function to add a new journal entry
void addJournalEntry(
    List<JournalEntry> journalEntries, String content, String mood) {
  journalEntries.insert(
    0,
    JournalEntry(
      title: "Entry",
      content: content,
      dateTime: DateTime.now().toString(),
      mood: mood, // Use the selected mood value
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
                journalEntries, contentController.text, selectedMood);
          },
          child: Text('Add Journal Entry'),
        ),
      ],
    );
  }
}
