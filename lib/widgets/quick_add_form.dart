import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo_tag.dart';
import '../models/todo_priority.dart';
import '../providers/todo_provider.dart';
import '../utils/constants.dart';

class QuickAddForm extends ConsumerStatefulWidget {
  const QuickAddForm({super.key});

  @override
  ConsumerState<QuickAddForm> createState() => _QuickAddFormState();
}

class _QuickAddFormState extends ConsumerState<QuickAddForm> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  TodoTag _selectedTag = TodoTag.work; // Default to work
  TodoPriority _selectedPriority = TodoPriority.medium;
  DateTime? _dueDate;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {
        _hasText = _titleController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick title input
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Task title...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(
                Icons.task_alt,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              isDense: true,
            ),
            maxLines: null, // Allow unlimited lines
            minLines: 1, // Start with single line
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _quickCreateTask(),
          ),

          const SizedBox(height: 16),

          // Notes field (bigger, replacing description)
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Add notes about what needs to be done...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            maxLines: 4,
            minLines: 3,
          ),

          const SizedBox(height: 16),

          // Category and Priority row
          Row(
            children: [
              // Tag selection
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: AppConstants.captionStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<TodoTag>(
                        segments: TodoTag.values
                            .map((tag) => ButtonSegment(
                                  value: tag,
                                  label: Text(tag.displayName,
                                      style: const TextStyle(fontSize: 10)),
                                  icon: Icon(tag.icon, size: 12),
                                ))
                            .toList(),
                        selected: {_selectedTag},
                        onSelectionChanged: (Set<TodoTag> selection) {
                          setState(() {
                            _selectedTag = selection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Priority selection
            ],
          ),

          const SizedBox(height: 16),

          // Category and Priority row
          Row(
            children: [
              // Tag selection
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priority',
                      style: AppConstants.captionStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: TodoPriority.values
                          .map((priority) => ChoiceChip(
                                label: Text(
                                  priority.displayName,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _selectedPriority == priority
                                        ? Colors.white
                                        : priority.color,
                                  ),
                                ),
                                selected: _selectedPriority == priority,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(
                                        () => _selectedPriority = priority);
                                  }
                                },
                                selectedColor: priority.color,
                                backgroundColor:
                                    priority.color.withOpacity(0.1),
                                side: BorderSide(
                                    color: priority.color.withOpacity(0.3)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 0),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              // Priority selection
            ],
          ),

          const SizedBox(height: 16),

          // Due date - simple input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Due Date (optional)',
                style: AppConstants.captionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'DD/MM/YYYY',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                      style: AppConstants.captionStyle,
                      readOnly: true,
                      onTap: _selectDueDate,
                      controller: TextEditingController(
                        text: _dueDate != null
                            ? '${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}'
                            : '',
                      ),
                    ),
                  ),
                  if (_dueDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _dueDate = null),
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Create button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasText ? _createTask : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 6),
                  Text('Create Task'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  void _quickCreateTask() {
    if (_titleController.text.trim().isNotEmpty) {
      _createTask();
    }
  }

  void _createTask() {
    if (_titleController.text.trim().isEmpty) return;

    ref.read(todoListProvider.notifier).addTodo(
          title: _titleController.text.trim(),
          description: '', // No longer using description
          notes: _notesController.text.trim(),
          dueDate: _dueDate,
          priority: _selectedPriority,
          tag: _selectedTag,
        );

    // Clear form
    _titleController.clear();
    _notesController.clear();
    setState(() {
      _selectedTag = TodoTag.work; // Reset to default
      _selectedPriority = TodoPriority.medium;
      _dueDate = null;
      _hasText = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task created successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
