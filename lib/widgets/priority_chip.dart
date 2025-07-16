import 'package:flutter/material.dart';
import '../models/todo_priority.dart';
import '../utils/constants.dart';

class PriorityChip extends StatelessWidget {
  final TodoPriority priority;
  final bool isSmall;

  const PriorityChip({
    super.key,
    required this.priority,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: priority.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priority.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 6 : 8,
            height: isSmall ? 6 : 8,
            decoration: BoxDecoration(
              color: priority.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmall ? 3 : 4),
          Text(
            priority.displayName,
            style: (isSmall ? AppConstants.captionStyle : AppConstants.bodyStyle).copyWith(
              color: priority.color,
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}