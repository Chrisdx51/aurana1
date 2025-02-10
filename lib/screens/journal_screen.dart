import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/journal_entry.dart';

class JournalScreen extends StatefulWidget {
  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> journalEntries = [];
  final TextEditingController _contentController = TextEditingController();
  String selectedMood = "😊 Happy";
  File? _selectedImage;
  final List<String> _tags = [];
  bool isDarkMode = false;

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
        journalEntries = decodedData.map((item) => JournalEntry.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> entryList = journalEntries.map((entry) => entry.toJson()).toList();
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
            mood: selectedMood,
            imagePath: _selectedImage?.path,
            tags: List.from(_tags),
          ),
        );
      });
      _saveJournalEntries();
      _contentController.clear();
      _selectedImage = null;
      _tags.clear();
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = File(pickedFile!.path);
    });
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _addTag(String tag) {
    setState(() {
      _tags.add(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Spiritual Journal",
          style: TextStyle(
              fontFamily: 'DancingScript', fontSize: 20), // Adjusted font size
        ),
        backgroundColor: Colors.lightBlue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: _toggleDarkMode,
          ),
        ],
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
          SingleChildScrollView(
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
                              fontSize: 18, // Reduced font size
                              fontWeight: FontWeight.bold,
                              color: Colors.lightBlue.shade700,
                            ),
                          ),
                          Divider(),
                          if (journalEntries.first.imagePath != null)
                            Image.file(File(journalEntries.first.imagePath!)),
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
                          Text(
                            "Mood: ${journalEntries.first.mood}",
                            style: TextStyle(
                              fontSize: 12, color: Colors.grey),
                          ),
                          Wrap(
                            children: journalEntries.first.tags.map((tag) => Chip(label: Text(tag))).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                Text(
                  "Write in your Journal",
                  style: TextStyle(
                    fontSize: 16, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue.shade800,
                  ),
                ),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedMood,
                  items: [
                    "😊 Happy",
                    "😢 Sad",
                    "😐 Neutral",
                    "😄 Excited",
                    "😌 Calm"
                  ].map((mood) => DropdownMenuItem(
                    value: mood,
                    child: Text(mood),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMood = value!;
                    });
                  },
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
                  maxLines: 4, // Reduced size
                  style: TextStyle(fontSize: 16, fontFamily: 'DancingScript'), // Stylish writing
                ),
                SizedBox(height: 10),
                if (_selectedImage != null)
                  Image.file(_selectedImage!),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Attach Photo'),
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Add a tag",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        // Add tag logic here
                      },
                    ),
                  ),
                  onSubmitted: _addTag,
                ),
                Wrap(
                  children: _tags.map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  )).toList(),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: _addJournalEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue.shade700,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8), // Reduced size
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      "Save Entry",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Past Journal Entries",
                  style: TextStyle(
                    fontSize: 16, // Reduced font size
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
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
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
        ],
      ),
    );
  }
}