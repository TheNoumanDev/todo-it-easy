import 'package:json_annotation/json_annotation.dart';
import 'todo_status.dart';
import 'todo_priority.dart';
import 'todo_tag.dart';

part 'todo.g.dart';

@JsonSerializable()
class Todo {
  final String id;
  final String title;
  final String description;
  final String notes;
  final DateTime createdAt;
  final DateTime? dueDate;
  final TodoStatus status;
  final TodoPriority priority;
  final TodoTag tag;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.notes = '',
    required this.createdAt,
    this.dueDate,
    this.status = TodoStatus.todo,
    this.priority = TodoPriority.medium,
    required this.tag,
  });

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    String? notes,
    DateTime? createdAt,
    DateTime? dueDate,
    TodoStatus? status,
    TodoPriority? priority,
    TodoTag? tag,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tag: tag ?? this.tag,
    );
  }

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
  Map<String, dynamic> toJson() => _$TodoToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, status: $status, priority: $priority, tag: $tag)';
  }
}