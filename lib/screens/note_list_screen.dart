import 'dart:convert'; // For jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    as quill; // Import Quill with prefix
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import 'package:todo/models/note.dart';
import 'package:todo/providers/note_provider.dart';
import 'package:todo/screens/add_edit_note_screen.dart'; // Will create next

class NoteListScreen extends StatelessWidget {
  const NoteListScreen({super.key});

  // Navigate to Add/Edit screen (pass null for adding, note for editing)
  void _navigateToAddEditNote(BuildContext context, Note? note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(note: note),
        fullscreenDialog: true, // Use a fullscreen dialog for adding/editing
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          final notes = noteProvider.notes;

          // Sort notes by updated date, newest first
          notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          if (notes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notes yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Tap the + button to add one.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Display notes in a ListView or GridView
          // Using ListView for simplicity here
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _buildNoteItem(context, note, noteProvider);
            },
          );
        },
      ),
      // FAB removed - will be handled by HomeScreen
    );
  }

  // Helper widget to build each Note item with modern styling
  Widget _buildNoteItem(
    BuildContext context,
    Note note,
    NoteProvider provider,
  ) {
    // Date Formatter
    final DateFormat formatter = DateFormat('MMM dd, yyyy - hh:mm a');
    String contentSnippet = 'No content';

    try {
      if (note.content.isNotEmpty) {
        final deltaJson = jsonDecode(note.content) as List<dynamic>;
        final document = quill.Document.fromJson(deltaJson);
        contentSnippet = document.toPlainText().trim().replaceAll(
          '\n',
          ' ',
        ); // Replace newlines with spaces for snippet
        if (contentSnippet.isEmpty) {
          contentSnippet = 'No text content';
        }
      }
    } catch (e) {
      print("Error parsing note content for snippet: $e");
      contentSnippet = "Error displaying content";
    }

    return Card(
      // Using CardTheme defined in main.dart
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
        title: Text(
          note.title.isEmpty ? "Untitled Note" : note.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            contentSnippet.isNotEmpty
                ? contentSnippet
                : 'Last updated: ${formatter.format(note.updatedAt)}',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            maxLines: 2, // Show a couple of lines of content
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Colors.redAccent.withOpacity(0.8),
          ),
          tooltip: 'Delete Note',
          onPressed: () {
            // Optional: Show confirmation dialog
            showDialog(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Delete Note?'),
                    content: const Text(
                      'Are you sure you want to delete this note? This action cannot be undone.',
                    ),
                    backgroundColor: Theme.of(context).cardTheme.color,
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text('Delete'),
                        onPressed: () {
                          provider.deleteNote(note.id);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
            );
          },
        ),
        onTap:
            () =>
                _navigateToAddEditNote(context, note), // Pass note for editing
      ),
    );
  }
}
