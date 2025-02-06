import 'package:flutter/material.dart';

class Message {
  String sender;
  String text;
  bool isMe;

  Message({
    required this.sender,
    required this.text,
    required this.isMe,
  });
}

List<Message> messages = [
  Message(sender: 'Sophia', text: 'Hey! How’s your spiritual journey going?', isMe: false),
  Message(sender: 'You', text: 'It’s been great! I’ve been meditating daily.', isMe: true),
  Message(sender: 'Sophia', text: 'That’s amazing! Keep going. ✨', isMe: false),
];
