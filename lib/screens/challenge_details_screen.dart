import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChallengeDetailsScreen extends StatefulWidget {
  final String title;
  final String description;
  final List<String> tasks;

  ChallengeDetailsScreen({required this.title, required this.description, required this.tasks});

  @override
  _ChallengeDetailsScreenState createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  late List<bool> taskCompletion;

  @override
  void initState() {
    super.initState();
    _initializeTaskProgress();
  }

  // 📌 Initialize task progress with proper error handling
  Future<void> _initializeTaskProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedProgress = prefs.getString(widget.title);

    if (savedProgress != null) {
      try {
        List<bool> loadedProgress = List<bool>.from(json.decode(savedProgress));
        if (loadedProgress.length == widget.tasks.length) {
          setState(() {
            taskCompletion = loadedProgress;
          });
          return;
        }
      } catch (e) {
        print("Error loading progress: $e");
      }
    }

    // ✅ If no saved progress exists or data is corrupted, initialize correctly
    setState(() {
      taskCompletion = List<bool>.filled(widget.tasks.length, false);
    });
  }

  // 📌 Save progress when tasks are checked
  Future<void> _saveTaskProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.title, json.encode(taskCompletion));
  }

  @override
  Widget build(BuildContext context) {
    int completedTasks = taskCompletion.where((task) => task).length;
    double progress = completedTasks / widget.tasks.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.blue.shade300),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description, style: TextStyle(fontSize: 16, color: Colors.black87)),
            SizedBox(height: 20),
            
            // 📌 Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 10),
            Text("Progress: ${completedTasks}/${widget.tasks.length} completed", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),

            SizedBox(height: 20),

            // 📌 List of Tasks
            Expanded(
              child: ListView.builder(
                itemCount: widget.tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Checkbox(
                        value: taskCompletion[index],
                        onChanged: (bool? value) {
                          setState(() {
                            taskCompletion[index] = value ?? false;
                          });
                          _saveTaskProgress(); // Save progress on change
                        },
                      ),
                      title: Text(widget.tasks[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
