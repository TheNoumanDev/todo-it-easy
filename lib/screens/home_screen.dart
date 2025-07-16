import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo_tag.dart';
import '../models/todo_status.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/status_column.dart';
import '../widgets/add_todo_dialog.dart';
import '../widgets/quick_add_form.dart';
import '../utils/constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosByStatus = ref.watch(todosByStatusProvider);
    final stats = ref.watch(todoStatsProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 24),
            SizedBox(width: 8),
            Text('Task Manager'),
          ],
        ),
        actions: [
          // Stats indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(TodoTag.work.icon, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text('${stats.workCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Icon(TodoTag.personal.icon, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text('${stats.personalCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Menu button
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_completed':
                  ref.read(todoListProvider.notifier).clearCompletedTodos();
                  break;
                case 'clear_all':
                  _showClearAllDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Clear Completed'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Compact Stats section
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingSmall,
            ),
            child: _buildCompactStats(stats),
          ),
          // Kanban board with Add Task column
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Task Column
                  Padding(
                    padding: const EdgeInsets.only(right: AppConstants.paddingMedium),
                    child: _buildAddTaskColumn(),
                  ),
                  // Status Columns (all 5, with smart drag restrictions)
                  ...TodoStatus.values.map((status) {
                    final todosForStatus = todosByStatus[status] ?? [];
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: AppConstants.paddingMedium),
                      child: DragTarget<Todo>(
                        onWillAccept: (todo) {
                          if (todo == null) return false;
                          // Check if this status is valid for the todo's tag
                          final validStatuses = ref.read(validDropStatusesProvider(todo.tag));
                          return validStatuses.contains(status);
                        },
                        onAccept: (todo) {
                          ref.read(todoListProvider.notifier).updateTodoStatus(todo.id, status);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return StatusColumn(
                            status: status,
                            todos: todosForStatus,
                            isHighlighted: candidateData.isNotEmpty,
                            hasRejectedData: rejectedData.isNotEmpty,
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats(TodoStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        child: Row(
          children: [
            Text(
              'Overview',
              style: AppConstants.titleStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(width: 24),
            _buildCompactStatItem('Total', stats.total, Colors.grey[600]!),
            _buildCompactStatItem('To Do', stats.todo, Colors.grey[600]!),
            _buildCompactStatItem('Progress', stats.inProgress, Colors.blue[600]!),
            _buildCompactStatItem('Pending', stats.pending, Colors.orange[600]!),
            _buildCompactStatItem('Review', stats.needsReview, Colors.purple[600]!),
            _buildCompactStatItem('Done', stats.completed, Colors.green[600]!),
            const Spacer(),
            // Tag breakdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(TodoTag.work.icon, size: 16, color: TodoTag.work.color),
                  const SizedBox(width: 4),
                  Text('${stats.workCount}', style: AppConstants.captionStyle.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Icon(TodoTag.personal.icon, size: 16, color: TodoTag.personal.color),
                  const SizedBox(width: 4),
                  Text('${stats.personalCount}', style: AppConstants.captionStyle.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (stats.total > 0)
              Container(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${((stats.completed / stats.total) * 100).toInt()}% Complete',
                      style: AppConstants.captionStyle.copyWith(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: stats.completed / stats.total,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                      minHeight: 4,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: AppConstants.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppConstants.captionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskColumn() {
    return Container(
      width: AppConstants.columnWidth,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2), width: 2, strokeAlign: BorderSide.strokeAlignInside),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                topRight: Radius.circular(AppConstants.borderRadiusLarge),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add New Task',
                  style: AppConstants.titleStyle.copyWith(
                    color: AppConstants.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Quick Add Form
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: _buildQuickAddForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddForm() {
    return Consumer(
      builder: (context, ref, child) {
        return const QuickAddForm();
      },
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Tasks'),
        content: const Text('Are you sure you want to delete all tasks? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(todoListProvider.notifier).clearAllTodos();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}