import 'package:flutter/material.dart';

class JournalEntry {
  String title;
  String content;
  String dateTime;

  JournalEntry({
    required this.title,
    required this.content,
    required this.dateTime,
  });
}

List<JournalEntry> journalEntries = [];
