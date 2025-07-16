import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../models/todo_status.dart';
import '../utils/constants.dart';
import 'todo_card.dart';

class StatusColumn extends StatelessWidget {
  final TodoStatus status;
  final List<Todo> todos;
  final bool isHighlighted;
  final bool hasRejectedData;

  const StatusColumn({
    super.key,
    required this.status,
    required this.todos,
    this.isHighlighted = false,
    this.hasRejectedData = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.columnWidth,
      decoration: BoxDecoration(
        color: isHighlighted 
            ? _getStatusColor(status).withOpacity(0.1)
            : hasRejectedData
                ? Colors.red[50]
                : AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: isHighlighted 
              ? _getStatusColor(status).withOpacity(0.5)
              : hasRejectedData
                  ? Colors.red[300]!
                  : AppConstants.borderColor,
          width: isHighlighted || hasRejectedData ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                topRight: Radius.circular(AppConstants.borderRadiusLarge),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.displayName,
                    style: AppConstants.titleStyle.copyWith(
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${todos.length}',
                    style: AppConstants.captionStyle.copyWith(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Todo cards
          Expanded(
            child: todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tasks',
                          style: AppConstants.bodyStyle.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      return Draggable<Todo>(
                        data: todos[index],
                        feedback: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          child: Container(
                            width: AppConstants.columnWidth - 32,
                            child: TodoCard(todo: todos[index], isDragging: true),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: TodoCard(todo: todos[index]),
                        ),
                        child: TodoCard(todo: todos[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TodoStatus status) {
    switch (status) {
      case TodoStatus.todo:
        return Colors.grey[600]!;
      case TodoStatus.pending:
        return Colors.orange[600]!;
      case TodoStatus.doing:
        return Colors.blue[600]!;
      case TodoStatus.needsReview:
        return Colors.purple[600]!;
      case TodoStatus.done:
        return Colors.green[600]!;
    }
  }

  IconData _getStatusIcon(TodoStatus status) {
    switch (status) {
      case TodoStatus.todo:
        return Icons.radio_button_unchecked;
      case TodoStatus.pending:
        return Icons.schedule;
      case TodoStatus.doing:
        return Icons.play_circle;
      case TodoStatus.needsReview:
        return Icons.rate_review;
      case TodoStatus.done:
        return Icons.check_circle;
    }
  }
}