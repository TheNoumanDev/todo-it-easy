import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../models/todo_status.dart';
import '../models/todo_priority.dart';
import '../models/todo_tag.dart';
import '../providers/todo_provider.dart';
import '../utils/constants.dart';
import 'priority_chip.dart';

class TodoCard extends ConsumerStatefulWidget {
  final Todo todo;
  final bool isDragging;

  const TodoCard({super.key, required this.todo, this.isDragging = false});

  @override
  ConsumerState<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends ConsumerState<TodoCard> {
  bool _isExpanded = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.todo.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      elevation: widget.isDragging ? 8 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        onTap: widget.isDragging ? null : () => setState(() => _isExpanded = !_isExpanded),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.todo.title,
                          style: AppConstants.titleStyle.copyWith(
                            fontSize: 16,
                            decoration: widget.todo.status == TodoStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (widget.todo.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.todo.description,
                            style: AppConstants.bodyStyle.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityChip(priority: widget.todo.priority),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status and date row
              Row(
                children: [
                  // Editable tag
                  InkWell(
                    onTap: widget.isDragging ? null : _showTagSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.todo.tag.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: widget.todo.tag.color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.todo.tag.icon,
                            size: 14,
                            color: widget.todo.tag.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.todo.tag.displayName,
                            style: AppConstants.captionStyle.copyWith(
                              color: widget.todo.tag.color,
                            ),
                          ),
                          if (!widget.isDragging)
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: widget.todo.tag.color.withOpacity(0.7),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.todo.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDueDateColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getDueDateColor().withOpacity(0.3)),
                      ),
                      child: Text(
                        DateFormat('MMM dd').format(widget.todo.dueDate!),
                        style: AppConstants.captionStyle.copyWith(
                          color: _getDueDateColor(),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Action buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusButton(),
                  const SizedBox(width: 8),
                  _buildPriorityButton(),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red[400],
                    onPressed: _showDeleteDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              // Expanded section
              if (_isExpanded) ...[
                const Divider(),
                _buildExpandedSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton() {
    return PopupMenuButton<TodoStatus>(
      onSelected: (status) {
        ref.read(todoListProvider.notifier).updateTodoStatus(widget.todo.id, status);
      },
      itemBuilder: (context) => TodoStatus.values.map((status) => 
        PopupMenuItem(
          value: status,
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
              Text(status.displayName),
            ],
          ),
        )
      ).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(widget.todo.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _getStatusColor(widget.todo.status).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(widget.todo.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.todo.status.displayName,
              style: AppConstants.captionStyle.copyWith(
                color: _getStatusColor(widget.todo.status),
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton() {
    return PopupMenuButton<TodoPriority>(
      onSelected: (priority) {
        ref.read(todoListProvider.notifier).updateTodoPriority(widget.todo.id, priority);
      },
      itemBuilder: (context) => TodoPriority.values.map((priority) => 
        PopupMenuItem(
          value: priority,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: priority.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(priority.displayName),
            ],
          ),
        )
      ).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.todo.priority.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: widget.todo.priority.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.todo.priority.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.todo.priority.displayName,
              style: AppConstants.captionStyle.copyWith(
                color: widget.todo.priority.color,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes:',
          style: AppConstants.subtitleStyle,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'Add notes about what needs to be done...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 3,
          onChanged: (value) {
            ref.read(todoListProvider.notifier).updateTodoNotes(widget.todo.id, value);
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.todo.createdAt)}',
          style: AppConstants.captionStyle,
        ),
      ],
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

  Color _getDueDateColor() {
    if (widget.todo.dueDate == null) return Colors.grey;
    
    final now = DateTime.now();
    final dueDate = widget.todo.dueDate!;
    final daysDiff = dueDate.difference(now).inDays;
    
    if (daysDiff < 0) return Colors.red; // Overdue
    if (daysDiff <= 1) return Colors.orange; // Due soon
    return Colors.blue; // Future
  }

  void _showTagSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TodoTag.values.map((tag) => 
            ListTile(
              leading: Icon(tag.icon, color: tag.color),
              title: Text(tag.displayName),
              onTap: () {
                ref.read(todoListProvider.notifier).updateTodo(
                  widget.todo.copyWith(tag: tag)
                );
                Navigator.pop(context);
              },
              trailing: widget.todo.tag == tag 
                  ? Icon(Icons.check, color: tag.color)
                  : null,
            )
          ).toList(),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${widget.todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(todoListProvider.notifier).deleteTodo(widget.todo.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}