class JournalEntry {
  String title;
  String content;
  String dateTime;
  String mood;

  JournalEntry({
    required this.title,
    required this.content,
    required this.dateTime,
    required this.mood,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      title: json['title'],
      content: json['content'],
      dateTime: json['dateTime'],
      mood: json['mood'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'dateTime': dateTime,
      'mood': mood,
    };
  }
}