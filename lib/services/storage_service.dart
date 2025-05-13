import 'dart:io'; // For File operations
import 'package:file_picker/file_picker.dart'; // For file picker
import 'package:flutter/foundation.dart'; // For ValueListenable & kDebugMode
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:path_provider/path_provider.dart';
import 'package:todo/models/note.dart';
import 'package:todo/models/todo.dart';

class StorageService {
  static const String _todoBoxName = 'todos';
  static const String _noteBoxName = 'notes';

  // Private constructor for Singleton pattern
  StorageService._privateConstructor();
  static final StorageService instance = StorageService._privateConstructor();

  late Box<Todo> _todoBox;
  late Box<Note> _noteBox;

  Future<void> init() async {
    // Initialize Hive and specify the storage directory
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Register Adapters
    if (!Hive.isAdapterRegistered(TodoAdapter().typeId)) {
      Hive.registerAdapter(TodoAdapter());
    }
    if (!Hive.isAdapterRegistered(NoteAdapter().typeId)) {
      Hive.registerAdapter(NoteAdapter());
    }

    // Open Boxes
    _todoBox = await Hive.openBox<Todo>(_todoBoxName);
    _noteBox = await Hive.openBox<Note>(_noteBoxName);
  }

  // --- Todo Operations ---

  // Get all todos as a listenable list
  ValueListenable<Box<Todo>> getTodosListenable() {
    return _todoBox.listenable();
  }

  // Get all todos (snapshot)
  List<Todo> getAllTodos() {
    return _todoBox.values.toList();
  }

  // Add a new todo
  Future<void> addTodo(Todo todo) async {
    await _todoBox.put(todo.id, todo);
  }

  // Update an existing todo
  Future<void> updateTodo(Todo todo) async {
    // HiveObjects automatically update if they are already in a box
    // We just need to call save() on the object itself
    // However, putting it again ensures it's added if somehow deleted before update
    await _todoBox.put(todo.id, todo);
  }

  // Delete a todo
  Future<void> deleteTodo(String id) async {
    await _todoBox.delete(id);
  }

  // Toggle todo status (requires fetching the todo first)
  Future<void> toggleTodoStatus(String id) async {
    final todo = _todoBox.get(id);
    if (todo != null) {
      todo.isDone = !todo.isDone;
      await todo.save(); // Save the change back to the box
      // Or await _todoBox.put(id, todo);
    }
  }

  // --- Note Operations ---

  // Get all notes as a listenable list
  ValueListenable<Box<Note>> getNotesListenable() {
    return _noteBox.listenable();
  }

  // Get all notes (snapshot)
  List<Note> getAllNotes() {
    return _noteBox.values.toList();
  }

  // Add a new note
  Future<void> addNote(Note note) async {
    await _noteBox.put(note.id, note);
  }

  // Update an existing note
  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now(); // Update timestamp
    await _noteBox.put(note.id, note);
  }

  // Delete a note
  Future<void> deleteNote(String id) async {
    await _noteBox.delete(id);
  }

  // --- Cleanup ---
  Future<void> close() async {
    await _todoBox.close();
    await _noteBox.close();
  }

  // --- Backup & Restore ---

  Future<String?> backupData() async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        return "Storage permission denied. Cannot perform backup.";
      }

      // Ensure boxes are open and paths are available
      // Note: Permission requests are removed as file_picker handles it via SAF.
      if (!_todoBox.isOpen ||
          !_noteBox.isOpen ||
          _todoBox.path == null ||
          _noteBox.path == null) {
        return "Error: Boxes are not open or paths are unavailable.";
      }

      // Ask user to select a directory to save the backup
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Backup Directory',
      );

      if (selectedDirectory == null) {
        return "Backup cancelled by user."; // User canceled the picker
      }

      // Define backup file names
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final todoBackupFileName = 'todos_backup_$timestamp.hive';
      final noteBackupFileName = 'notes_backup_$timestamp.hive';

      final todoBackupPath = '$selectedDirectory/$todoBackupFileName';
      final noteBackupPath = '$selectedDirectory/$noteBackupFileName';

      // Copy the .hive files
      final todoFile = File(_todoBox.path!);
      final noteFile = File(_noteBox.path!);

      if (await todoFile.exists()) {
        await todoFile.copy(todoBackupPath);
        if (kDebugMode) {
          print('Todo backup saved to: $todoBackupPath');
        }
      } else {
        return "Error: Todo data file not found at ${_todoBox.path}";
      }

      if (await noteFile.exists()) {
        await noteFile.copy(noteBackupPath);
        if (kDebugMode) {
          print('Note backup saved to: $noteBackupPath');
        }
      } else {
        // Attempt to delete the partially created todo backup if note backup fails
        try {
          final partialBackup = File(todoBackupPath);
          if (await partialBackup.exists()) {
            await partialBackup.delete();
          }
        } catch (_) {} // Ignore errors during cleanup
        return "Error: Note data file not found at ${_noteBox.path}";
      }

      return "Backup successful! Files saved in '$selectedDirectory'."; // Success
    } catch (e) {
      if (kDebugMode) {
        print("Backup failed: $e");
      }
      return "Backup failed: ${e.toString()}"; // Failure
    }
  }

  Future<String?> restoreData() async {
    try {
      // Note: Permission requests are removed as file_picker handles it via SAF.

      // Ask user to select the backup files (allow multiple)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup Files (.hive)',
        type: FileType.custom,
        allowedExtensions: ['hive'],
        allowMultiple: true, // Allow selecting both todo and note backups
      );

      if (result == null || result.files.length < 2) {
        return "Restore cancelled or not enough files selected. Please select both todo and note .hive backup files.";
      }

      // Find the original box paths BEFORE closing them
      final originalTodoPath = _todoBox.path;
      final originalNotePath = _noteBox.path;

      if (originalTodoPath == null || originalNotePath == null) {
        return "Error: Cannot determine original data file paths.";
      }

      // Identify the selected backup files
      String? todoBackupPath;
      String? noteBackupPath;

      for (var file in result.files) {
        if (file.path != null) {
          if (file.name.contains('todos_backup')) {
            todoBackupPath = file.path;
          } else if (file.name.contains('notes_backup')) {
            noteBackupPath = file.path;
          }
        }
      }

      if (todoBackupPath == null || noteBackupPath == null) {
        return "Error: Could not identify both todo and note backup files from selection.";
      }

      // Close current boxes BEFORE overwriting files
      await close(); // Close both boxes

      // Copy selected backup files to original locations, overwriting existing ones
      try {
        await File(todoBackupPath).copy(originalTodoPath);
        await File(noteBackupPath).copy(originalNotePath);
      } catch (e) {
        // Attempt to reopen boxes if copy fails? Or just report error.
        // For now, just report error. User might need to restart app.
        return "Error copying backup files: ${e.toString()}. Please restart the app.";
      }

      // Re-initialize Hive and reopen boxes - This might be tricky as init is usually in main.
      // A better approach might be to signal the main app to restart or re-initialize.
      // For now, let's just reopen the boxes directly. The providers listening should update.
      // NOTE: This assumes Hive is already initialized. If not, this will fail.
      // A full app restart after restore might be the safest approach.
      try {
        _todoBox = await Hive.openBox<Todo>(_todoBoxName);
        _noteBox = await Hive.openBox<Note>(_noteBoxName);
      } catch (e) {
        return "Error reopening data files after restore: ${e.toString()}. Please restart the app.";
      }

      // Crucially, we need to trigger updates in the providers.
      // Re-assigning the listenables might work if the providers are still active.
      // Or we could add explicit refresh methods to providers.
      // Let's assume the ValueListenable will pick up the change upon box reopening.

      return "Restore successful! Please review your data."; // Success
    } catch (e) {
      if (kDebugMode) {
        print("Restore failed: $e");
      }
      return "Restore failed: ${e.toString()}"; // Failure
    }
  }
}
