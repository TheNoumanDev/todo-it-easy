import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';
import '../models/todo_tag.dart';
import '../models/todo_status.dart';
import '../models/todo_priority.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';

// Main todo list provider
final todoListProvider = StateNotifierProvider<TodoListNotifier, List<Todo>>((ref) {
  return TodoListNotifier();
});

// All todos sorted by priority and creation date
final allTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  
  return todos.toList()
    ..sort((a, b) {
      // Sort by priority first, then by creation date
      if (a.priority.sortOrder != b.priority.sortOrder) {
        return b.priority.sortOrder.compareTo(a.priority.sortOrder);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
});

// Valid drop targets for a given tag
final validDropStatusesProvider = Provider.family<List<TodoStatus>, TodoTag>((ref, tag) {
  if (tag == TodoTag.personal) {
    return [TodoStatus.todo, TodoStatus.pending, TodoStatus.done];
  } else {
    return TodoStatus.values;
  }
});

// All todos by status (mixed Work and Personal)
final todosByStatusProvider = Provider<Map<TodoStatus, List<Todo>>>((ref) {
  final allTodos = ref.watch(allTodosProvider);
  final Map<TodoStatus, List<Todo>> todosByStatus = {};
  
  for (final status in TodoStatus.values) {
    todosByStatus[status] = allTodos
        .where((todo) => todo.status == status)
        .toList();
  }
  
  return todosByStatus;
});

// Combined stats for all tasks
final todoStatsProvider = Provider<TodoStats>((ref) {
  final allTodos = ref.watch(allTodosProvider);
  
  final workTasks = allTodos.where((t) => t.tag == TodoTag.work).toList();
  final personalTasks = allTodos.where((t) => t.tag == TodoTag.personal).toList();
  
  return TodoStats(
    total: allTodos.length,
    todo: allTodos.where((t) => t.status == TodoStatus.todo).length,
    inProgress: allTodos.where((t) => t.status == TodoStatus.doing).length,
    completed: allTodos.where((t) => t.status == TodoStatus.done).length,
    needsReview: allTodos.where((t) => t.status == TodoStatus.needsReview).length,
    pending: allTodos.where((t) => t.status == TodoStatus.pending).length,
    workCount: workTasks.length,
    personalCount: personalTasks.length,
  );
});

class TodoStats {
  final int total;
  final int todo;
  final int inProgress;
  final int completed;
  final int needsReview;
  final int pending;
  final int workCount;
  final int personalCount;

  TodoStats({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.completed,
    required this.needsReview,
    required this.pending,
    required this.workCount,
    required this.personalCount,
  });
}

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final _uuid = const Uuid();
  
  TodoListNotifier() : super([]) {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await StorageService.loadTodos();
    state = todos;
  }

  Future<void> _saveTodos() async {
    await StorageService.saveTodos(state);
  }

  void addTodo({
    required String title,
    String description = '',
    String notes = '',
    DateTime? dueDate,
    TodoPriority priority = TodoPriority.medium,
    TodoTag tag = TodoTag.work, // Default to work
  }) {
    final newTodo = Todo(
      id: _uuid.v4(),
      title: title,
      description: description,
      notes: notes,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priority: priority,
      tag: tag,
    );
    
    state = [...state, newTodo];
    _saveTodos();
  }

  void updateTodo(Todo updatedTodo) {
    state = state.map((todo) => 
      todo.id == updatedTodo.id ? updatedTodo : todo
    ).toList();
    _saveTodos();
  }

  void deleteTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
    _saveTodos();
  }

  void updateTodoStatus(String id, TodoStatus newStatus) {
    state = state.map((todo) {
      if (todo.id == id) {
        // For personal tasks, ensure status is valid
        if (todo.tag == TodoTag.personal) {
          if (newStatus == TodoStatus.doing || newStatus == TodoStatus.needsReview) {
            // Convert invalid statuses to pending for personal tasks
            return todo.copyWith(status: TodoStatus.pending);
          }
        }
        return todo.copyWith(status: newStatus);
      }
      return todo;
    }).toList();
    _saveTodos();
  }

  void updateTodoPriority(String id, TodoPriority newPriority) {
    state = state.map((todo) => 
      todo.id == id ? todo.copyWith(priority: newPriority) : todo
    ).toList();
    _saveTodos();
  }

  void updateTodoNotes(String id, String notes) {
    state = state.map((todo) => 
      todo.id == id ? todo.copyWith(notes: notes) : todo
    ).toList();
    _saveTodos();
  }

  void clearCompletedTodos() {
    state = state.where((todo) => todo.status != TodoStatus.done).toList();
    _saveTodos();
  }

  void clearAllTodos() {
    state = [];
    _saveTodos();
  }

  // Method to migrate personal tasks to valid statuses
  void migratePersonalTaskStatuses() {
    state = state.map((todo) {
      if (todo.tag == TodoTag.personal) {
        if (todo.status == TodoStatus.doing || todo.status == TodoStatus.needsReview) {
          return todo.copyWith(status: TodoStatus.pending);
        }
      }
      return todo;
    }).toList();
    _saveTodos();
  }
}