import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo/models/todo.dart';
import 'package:todo/services/storage_service.dart';

class TodoProvider with ChangeNotifier {
  final StorageService _storageService = StorageService.instance;
  late ValueListenable<Box<Todo>> _todosListenable;

  TodoProvider() {
    // Get the listenable from the storage service
    _todosListenable = _storageService.getTodosListenable();
    // Add a listener to notify consumers when the box changes
    _todosListenable.addListener(_onTodoBoxChanged);
  }

  // Expose the list of active (not deleted) todos
  List<Todo> get todos {
    return _todosListenable.value.values
        .where((todo) => !todo.isDeleted)
        .toList()
        .cast<Todo>();
  }

  // Expose the list of trashed (soft-deleted) todos
  List<Todo> get trashedTodos {
    return _todosListenable.value.values
        .where((todo) => todo.isDeleted)
        .toList()
        .cast<Todo>();
  }

  // Method called when the Hive box notifies of a change
  void _onTodoBoxChanged() {
    notifyListeners(); // Notify all listening widgets to rebuild
  }

  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) return; // Avoid adding empty todos
    final newTodo = Todo(title: title.trim());
    await _storageService.addTodo(newTodo);
    // No need to call notifyListeners() here, the box listener handles it
  }

  Future<void> toggleTodoStatus(String id) async {
    await _storageService.toggleTodoStatus(id);
    // Listener handles notification
  }

  Future<void> updateTodoTitle(String id, String newTitle) async {
    final todo = _storageService.getTodosListenable().value.get(id);
    if (todo != null && newTitle.trim().isNotEmpty) {
      todo.title = newTitle.trim();
      await _storageService.updateTodo(todo); // Use updateTodo which calls put
      // Listener handles notification
    }
  }

  Future<void> softDeleteTodo(String id) async {
    final todo = _todosListenable.value.get(id);
    if (todo != null) {
      todo.isDeleted = true;
      todo.deletedAt = DateTime.now();
      await _storageService.updateTodo(todo); // Save changes
      // Listener handles notification
    }
  }

  Future<void> restoreTodo(String id) async {
    final todo = _todosListenable.value.get(id);
    if (todo != null && todo.isDeleted) {
      todo.isDeleted = false;
      todo.deletedAt = null; // Clear deletion timestamp
      await _storageService.updateTodo(todo); // Save changes
      // Listener handles notification
    }
  }

  // This will permanently delete from Hive
  Future<void> permanentlyDeleteTodo(String id) async {
    // First, ensure it's actually a soft-deleted item if that's the workflow
    // final todo = _todosListenable.value.get(id);
    // if (todo != null && todo.isDeleted) {
    await _storageService.deleteTodo(id); // This is the hard delete
    // Listener handles notification
    // }
  }

  // Clean up the listener when the provider is disposed
  @override
  void dispose() {
    _todosListenable.removeListener(_onTodoBoxChanged);
    super.dispose();
  }
}
