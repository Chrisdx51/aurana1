class JournalEntry {
  String title;
  String content;
  String dateTime;

  JournalEntry({required this.title, required this.content, required this.dateTime});

  // Convert JournalEntry object to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'dateTime': dateTime,
    };
  }

  // Convert JSON to JournalEntry object
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      title: json['title'],
      content: json['content'],
      dateTime: json['dateTime'],
    );
  }
}
//