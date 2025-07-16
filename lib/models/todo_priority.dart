import 'package:flutter/material.dart';

enum TodoPriority {
  low('Low', Colors.green, 1),
  medium('Medium', Colors.orange, 2),
  high('High', Colors.red, 3),
  urgent('Urgent', Colors.purple, 4);

  const TodoPriority(this.displayName, this.color, this.sortOrder);
  
  final String displayName;
  final Color color;
  final int sortOrder;

  static TodoPriority fromString(String value) {
    return TodoPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => TodoPriority.medium,
    );
  }
}