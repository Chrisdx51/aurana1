import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final String title;
  final String description;
  final List<String> tasks;

  ChallengeDetailsScreen({required this.title, required this.description, required this.tasks});

  @override
  _ChallengeDetailsScreenState createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  List<bool> taskCompletion = [];
  bool isReminderSet = false;

  @override
  void initState() {
    super.initState();
    _initializeTaskProgress();
    _loadReminderState();
  }

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
        } else {
          setState(() {
            taskCompletion = List<bool>.filled(widget.tasks.length, false);
          });
        }
      } catch (e) {
        print("Error loading progress: $e");
        setState(() {
          taskCompletion = List<bool>.filled(widget.tasks.length, false);
        });
      }
    } else {
      setState(() {
        taskCompletion = List<bool>.filled(widget.tasks.length, false);
      });
    }
  }

  Future<void> _saveTaskProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.title, json.encode(taskCompletion));
  }

  Future<void> _loadReminderState() async {
    isReminderSet = await NotificationService.loadReminderState('${widget.title}_reminder');
    setState(() {});
  }

  void _toggleReminder() async {
    if (isReminderSet) {
      await NotificationService.cancelNotification(widget.title.hashCode + 0);
      await NotificationService.cancelNotification(widget.title.hashCode + 1);
      await NotificationService.cancelNotification(widget.title.hashCode + 2);
      await NotificationService.saveReminderState('${widget.title}_reminder', false);
    } else {
      await NotificationService.scheduleDailyReminder(
        widget.title.hashCode + 0,
        "Morning Challenge Reminder",
        "Time to focus on your challenge: ${widget.title}!",
        10,
        0,
      );

      await NotificationService.scheduleDailyReminder(
        widget.title.hashCode + 1,
        "Afternoon Challenge Reminder",
        "Keep going! Have you completed your challenge today?",
        14,
        0,
      );

      await NotificationService.scheduleDailyReminder(
        widget.title.hashCode + 2,
        "Evening Challenge Reminder",
        "Great job! Take a moment to reflect on your progress.",
        18,
        0,
      );

      await NotificationService.saveReminderState('${widget.title}_reminder', true);
    }

    setState(() {
      isReminderSet = !isReminderSet;
    });
  }

  // 📌 Update Completed Challenge Count
  Future<void> _updateCompletedChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    int completedChallenges = prefs.getInt("completedChallenges") ?? 0;
    await prefs.setInt("completedChallenges", completedChallenges + 1);
  }

  void _checkCompletion() async {
    if (taskCompletion.every((task) => task)) {
      await _updateCompletedChallenges(); // ✅ Increases challenge count
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Challenge Completed 🎉"),
          content: Text("Congratulations! You have completed '${widget.title}' and earned a new medal! 🏅"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
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
            
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 10),
            Text("Progress: ${completedTasks}/${widget.tasks.length} completed", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),

            SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _toggleReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReminderSet ? Colors.red : Colors.blue,
                ),
                child: Text(isReminderSet ? "Disable Reminders" : "Enable Reminders"),
              ),
            ),

            SizedBox(height: 20),

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
                          _saveTaskProgress();
                          _checkCompletion(); // ✅ Check if the challenge is completed
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
