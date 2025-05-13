import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo/models/note.dart';
import 'package:todo/services/storage_service.dart';

class NoteProvider with ChangeNotifier {
  final StorageService _storageService = StorageService.instance;
  late ValueListenable<Box<Note>> _notesListenable;

  NoteProvider() {
    _notesListenable = _storageService.getNotesListenable();
    _notesListenable.addListener(_onNoteBoxChanged);
  }

  List<Note> get notes => _notesListenable.value.values.toList().cast<Note>();

  void _onNoteBoxChanged() {
    notifyListeners();
  }

  Future<void> addNote(String title, String content) async {
    if (title.trim().isEmpty && content.trim().isEmpty)
      return; // Avoid empty notes
    final newNote = Note(
      title:
          title.trim().isEmpty
              ? "Untitled Note"
              : title.trim(), // Default title
      content: content.trim(),
    );
    await _storageService.addNote(newNote);
  }

  Future<void> updateNote(String id, String newTitle, String newContent) async {
    final note = _storageService.getNotesListenable().value.get(id);
    if (note != null) {
      // Avoid saving if nothing changed except potentially whitespace
      final trimmedTitle = newTitle.trim();
      final trimmedContent = newContent.trim();
      if (note.title == trimmedTitle && note.content == trimmedContent) return;

      note.title = trimmedTitle.isEmpty ? "Untitled Note" : trimmedTitle;
      note.content = trimmedContent;
      // Storage service handles updating the timestamp
      await _storageService.updateNote(note);
    }
  }

  Future<void> deleteNote(String id) async {
    await _storageService.deleteNote(id);
  }

  @override
  void dispose() {
    _notesListenable.removeListener(_onNoteBoxChanged);
    super.dispose();
  }
}
