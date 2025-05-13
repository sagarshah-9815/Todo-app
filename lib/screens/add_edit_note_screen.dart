import 'dart:convert'; // For jsonEncode/Decode
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Import Quill
import 'package:provider/provider.dart';
import 'package:todo/models/note.dart';
import 'package:todo/providers/note_provider.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note; // Null if adding a new note, contains data if editing

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  late TextEditingController _titleController;
  late QuillController _quillController; // Use QuillController
  bool _isSaving = false;
  bool _isLoading = true; // To handle async document loading

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _initializeQuillController();
  }

  void _initializeQuillController() {
    Document document;
    try {
      if (widget.note != null && widget.note!.content.isNotEmpty) {
        // Decode the JSON string from the note content into a Delta
        // Ensure it's treated as List<dynamic> which fromJson expects
        final deltaJson = jsonDecode(widget.note!.content) as List<dynamic>;
        document = Document.fromJson(deltaJson);
      } else {
        // Create an empty document for a new note
        document = Document();
      }
    } catch (e) {
      // Handle potential JSON decoding errors or invalid format
      print("Error loading note content: $e");
      // Provide default content or indicate error
      document = Document()..insert(0, 'Error loading content.');
    }

    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Use WidgetsBinding to ensure build context is available if needed later
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Content loaded, update UI
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose(); // Dispose QuillController
    super.dispose();
  }

  Future<void> _saveNote() async {
    // Simple title check (can be enhanced)
    final title = _titleController.text.trim();
    // Check if document is empty (ignoring potential single newline character)
    final isDocumentEmpty =
        _quillController.document.length <= 1 &&
        _quillController.document.toPlainText().trim().isEmpty;

    if (title.isEmpty && isDocumentEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save an empty note.')),
      );
      return;
    }

    if (!_isSaving) {
      setState(() {
        _isSaving = true;
      });

      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      // Get Quill content as Delta, then encode to JSON string
      final deltaJson = _quillController.document.toDelta().toJson();
      final contentJsonString = jsonEncode(deltaJson);

      try {
        final finalTitle =
            title.isEmpty ? "Untitled Note" : title; // Use default if empty

        if (widget.note == null) {
          // Add new note (pass JSON string)
          await noteProvider.addNote(finalTitle, contentJsonString);
        } else {
          // Update existing note (pass JSON string)
          await noteProvider.updateNote(
            widget.note!.id,
            finalTitle,
            contentJsonString,
          );
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving note: ${e.toString()}')),
          );
        }
      } finally {
        // Ensure _isSaving is reset even if an error occurs
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while QuillController initializes
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'Add New Note' : 'Edit Note'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Add New Note' : 'Edit Note'),
        actions: [
          // Save button
          IconButton(
            icon:
                _isSaving
                    ? const SizedBox(
                      // Show progress indicator while saving
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.save_alt_outlined),
            tooltip: 'Save Note',
            onPressed:
                _isSaving ? null : _saveNote, // Disable button while saving
          ),
        ],
      ),
      body: Column(
        // Use Column instead of Padding -> Form
        children: <Widget>[
          // Title Field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                // labelText: 'Title', // Keep it simple
                hintText: 'Title',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textInputAction: TextInputAction.next,
              maxLines: 1,
            ),
          ),
          // Quill Toolbar
          QuillToolbar.simple(
            configurations: QuillSimpleToolbarConfigurations(
              controller: _quillController,
              sharedConfigurations: const QuillSharedConfigurations(
                locale: Locale('en'), // Set locale if needed
              ),
              multiRowsDisplay: false, // Keep toolbar compact
              // Customize toolbar options here
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true, // Corrected parameter name
              showStrikeThrough: false,
              showColorButton: true,
              showBackgroundColorButton: true,
              showClearFormat: true,
              showHeaderStyle: true, // For H1, H2, H3
              showListNumbers: true,
              showListBullets: true,
              showListCheck: true,
              showCodeBlock: true,
              showQuote: true,
              showIndent: true,
              showLink: true,
              showSearchButton: false, // Keep it simple
            ),
          ),
          const Divider(height: 1),
          // Quill Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _quillController,
                  sharedConfigurations: const QuillSharedConfigurations(
                    locale: Locale('en'),
                  ),
                  padding:
                      EdgeInsets
                          .zero, // Padding handled by parent Padding widget
                  // readOnly: false, // Default is false
                  // Other configurations like custom styles, scroll controller etc.
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
