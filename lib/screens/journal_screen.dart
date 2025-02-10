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

  Future<void> _loadJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedEntries = prefs.getString('journal_entries');
    if (savedEntries != null) {
      setState(() {
        List<dynamic> decodedData = json.decode(savedEntries);
        journalEntries =
            decodedData.map((item) => JournalEntry.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> entryList =
        journalEntries.map((entry) => entry.toJson()).toList();
    await prefs.setString('journal_entries', json.encode(entryList));
  }

  void _addJournalEntry() {
    String content = _contentController.text.trim();
    if (content.isNotEmpty) {
      setState(() {
        journalEntries.insert(
          0,
          JournalEntry(
            title: "Entry",
            content: content,
            dateTime: DateTime.now().toString(),
            mood: "Neutral",
          ),
        );
      });
      _saveJournalEntries();
      _contentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Journal entry saved!')),
      );
    }
  }

  void _deleteJournalEntry(int index) {
    setState(() {
      journalEntries.removeAt(index);
    });
    _saveJournalEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Spiritual Journal",
          style: TextStyle(fontFamily: 'DancingScript', fontSize: 20),
        ),
        backgroundColor: Colors.lightBlue.shade700,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/parchment_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (journalEntries.isNotEmpty)
                        Card(
                          color: Colors.white.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Last Entry",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightBlue.shade700,
                                  ),
                                ),
                                Divider(),
                                Text(
                                  journalEntries.first.content,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  journalEntries.first.dateTime,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 20),
                      Text(
                        "Write in your Journal",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue.shade800,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: "Start writing your thoughts here...",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        maxLines: 6,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: ElevatedButton(
                          onPressed: _addJournalEntry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue.shade700,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            "Save Entry",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Past Journal Entries",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue.shade800,
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: journalEntries.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              tileColor: Colors.white.withOpacity(0.9),
                              title: Text(
                                journalEntries[index].content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16),
                              ),
                              subtitle: Text(
                                journalEntries[index].dateTime,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteJournalEntry(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Chat Bar at the Bottom
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade700.withOpacity(0.9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: "Write your thoughts...",
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _addJournalEntry,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}