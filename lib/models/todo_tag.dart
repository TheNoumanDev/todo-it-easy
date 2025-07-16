import 'package:flutter/material.dart';

enum TodoTag {
  work('Work', Icons.work, Colors.blue),
  personal('Personal', Icons.home, Colors.teal);

  const TodoTag(this.displayName, this.icon, this.color);
  
  final String displayName;
  final IconData icon;
  final Color color;

  static TodoTag fromString(String value) {
    // Handle migration from old 'daily' to new 'personal'
    if (value == 'daily') {
      return TodoTag.personal;
    }
    return TodoTag.values.firstWhere(
      (tag) => tag.name == value,
      orElse: () => TodoTag.work,
    );
  }
}