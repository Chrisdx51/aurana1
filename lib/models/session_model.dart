import 'package:flutter/material.dart';

class Session {
  final String title;
  final String description;
  final DateTime date;
  final String videoUrl; // 🔹 Link to the live or recorded session

  Session({
    required this.title,
    required this.description,
    required this.date,
    required this.videoUrl,
  });

  // Convert session data to JSON for storage
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'videoUrl': videoUrl,
      };

  // Convert JSON back to a Session object
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      videoUrl: json['videoUrl'],
    );
  }
}
