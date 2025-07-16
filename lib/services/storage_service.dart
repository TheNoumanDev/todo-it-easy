import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class StorageService {
  static const String _todosKey = 'todos';
  static const String _selectedTagKey = 'selected_tag';

  // Save todos to local storage
  static Future<void> saveTodos(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = todos.map((todo) => todo.toJson()).toList();
    await prefs.setString(_todosKey, jsonEncode(todosJson));
  }

  // Load todos from local storage
  static Future<List<Todo>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosString = prefs.getString(_todosKey);
    
    if (todosString == null) return [];
    
    try {
      final List<dynamic> todosJson = jsonDecode(todosString);
      return todosJson.map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      print('Error loading todos: $e');
      return [];
    }
  }

  // Save selected tag (work/daily view)
  static Future<void> saveSelectedTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTagKey, tag);
  }

  // Load selected tag
  static Future<String?> loadSelectedTag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedTagKey);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}