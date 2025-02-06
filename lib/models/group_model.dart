import 'package:flutter/material.dart';

class Group {
  String name;
  String description;
  int members;

  Group({
    required this.name,
    required this.description,
    required this.members,
  });
}

List<Group> communityGroups = [
  Group(name: 'Beginner\'s Spirituality', description: 'A safe space for beginners to learn and grow.', members: 120),
  Group(name: 'Meditation Masters', description: 'A group for advanced meditation techniques.', members: 85),
  Group(name: 'Law of Attraction', description: 'Manifestation tips and success stories.', members: 150),
  Group(name: 'Energy Healing', description: 'Learn Reiki, Chakra balancing, and more.', members: 95),
];
