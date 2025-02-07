import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/journal_entry.dart';

class JournalScreen extends StatefulWidget {
  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> journalEntries = [];
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadJournalEntries();
  }

  // 📌 Load saved journal entries from SharedPreferences
  Future<void> _loadJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedEntries = prefs.getString('journal_entries');
    if (savedEntries != null) {
      setState(() {
        List<dynamic> decodedData = json.decode(savedEntries);
        journalEntries = decodedData.map((item) => JournalEntry.fromJson(item)).toList();
      });
    }
  }

  // 📌 Save journal entries to SharedPreferences
  Future<void> _saveJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> entryList = journalEntries.map((entry) => entry.toJson()).toList();
    await prefs.setString('journal_entries', json.encode(entryList));
  }

  // 📌 Add a new journal entry
  void _addJournalEntry() {
    String content = _contentController.text.trim();

    if (content.isNotEmpty) {
      setState(() {
        journalEntries.insert(
          0,
          JournalEntry(title: "Entry", content: content, dateTime: DateTime.now().toString()),
        );
      });
      _saveJournalEntries(); // Save entries permanently
      _contentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Journal entry saved!')));
    }
  }

  // 📌 Delete a journal entry
  void _deleteJournalEntry(int index) {
    setState(() {
      journalEntries.removeAt(index);
    });
    _saveJournalEntries(); // Update saved entries
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ✅ Fixes keyboard overflow issue
      appBar: AppBar(title: Text("My Spiritual Journal"), backgroundColor: Colors.blue.shade300),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // ✅ Closes keyboard when tapping outside
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 📌 Last Journal Entry Section (Unchanged)
                    journalEntries.isNotEmpty
                        ? Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: Colors.blue.shade100,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Last Entry",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  Divider(),
                                  Text(journalEntries.first.content, style: TextStyle(fontSize: 16)),
                                  SizedBox(height: 5),
                                  Text(journalEntries.first.dateTime, style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(),

                    SizedBox(height: 20),

                    // 📌 Always Visible Input Box
                    Text(
                      "New Journal Entry",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    Divider(),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: TextField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: "Write your thoughts here...",
                          border: InputBorder.none,
                        ),
                        maxLines: 6, // ✅ Allows for multi-line input
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                    SizedBox(height: 15),

                    // 📌 Centered "Save Entry" Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _addJournalEntry,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Save Entry', style: TextStyle(fontSize: 16)),
                      ),
                    ),

                    SizedBox(height: 20),

                    // 📌 Dedicated "Past Entries" Section
                    Text(
                      "My Journal Book",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    Divider(),

                    Container(
                      height: 300, // ✅ Sets a fixed height for scrolling
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: journalEntries.length > 1
                          ? ListView.builder(
                              itemCount: journalEntries.length - 1,
                              itemBuilder: (context, index) {
                                final entry = journalEntries[index + 1]; // Skips the latest entry
                                return Card(
                                  elevation: 3,
                                  margin: EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    title: Text(
                                      entry.content,
                                      style: TextStyle(fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(entry.dateTime, style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteJournalEntry(index + 1),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  "No past entries yet. Your journal book will grow with time!",
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
