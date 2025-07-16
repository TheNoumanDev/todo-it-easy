import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../models/todo_tag.dart';
import '../services/storage_service.dart';

// Provider for loading todos from storage
final todosFromStorageProvider = FutureProvider<List<Todo>>((ref) async {
  return await StorageService.loadTodos();
});

// Provider for selected tag
final selectedTagProvider = StateNotifierProvider<SelectedTagNotifier, TodoTag>((ref) {
  return SelectedTagNotifier();
});

class SelectedTagNotifier extends StateNotifier<TodoTag> {
  SelectedTagNotifier() : super(TodoTag.work) {
    _loadSelectedTag();
  }

  Future<void> _loadSelectedTag() async {
    final savedTag = await StorageService.loadSelectedTag();
    if (savedTag != null) {
      state = TodoTag.fromString(savedTag);
    }
  }

  void setTag(TodoTag tag) {
    state = tag;
    StorageService.saveSelectedTag(tag.name);
  }
}