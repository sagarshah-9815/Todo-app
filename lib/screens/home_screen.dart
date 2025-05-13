import 'dart:io'; // For Platform.isAndroid
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // For permission requests
import 'package:provider/provider.dart';
import 'package:todo/models/note.dart'; // Needed for _navigateToAddEditNote
import 'package:todo/providers/note_provider.dart'; // Needed for _navigateToAddEditNote
import 'package:todo/providers/todo_provider.dart'; // Needed for _showAddTodoDialog
import 'package:todo/screens/add_edit_note_screen.dart'; // Needed for _navigateToAddEditNote
import 'package:todo/screens/note_list_screen.dart';
import 'package:todo/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:todo/screens/todo_list_screen.dart';
// StorageService is not directly used here anymore for actions
// ThemeProvider is not directly used here anymore for actions

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Removed TickerProviderStateMixin
  int _selectedIndex = 0; // 0 for Todos, 1 for Notes
  // Removed AnimationController

  // List of widgets to display based on the selected index
  static final List<Widget> _widgetOptions = <Widget>[
    const TodoListScreen(),
    const NoteListScreen(),
  ];

  // List of titles for the AppBar
  static const List<String> _appBarTitles = <String>['My Todos', 'My Notes'];

  @override
  void initState() {
    super.initState();
    _requestStoragePermissionOnLaunch();
  }

  Future<void> _requestStoragePermissionOnLaunch() async {
    // Request storage permissions on Android at launch
    if (Platform.isAndroid) {
      PermissionStatus storageStatus = await Permission.storage.status;
      print(
        "HomeScreen initState: Initial storage permission status: $storageStatus",
      );

      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
        print(
          "HomeScreen initState: Storage permission status after request: $storageStatus",
        );
      }

      if (storageStatus.isPermanentlyDenied) {
        print(
          "HomeScreen initState: Storage permission permanently denied. Opening app settings...",
        );
        // Consider showing a dialog to the user before opening settings
        await openAppSettings();
      } else if (!storageStatus.isGranted) {
        print("HomeScreen initState: Storage permission was not granted.");
        // Optionally, show a dialog explaining why it's needed.
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- Action Methods (moved from child screens) ---

  // Function to show the Add Todo Dialog/Modal (from TodoListScreen)
  void _showAddTodoDialog(BuildContext context) {
    final TextEditingController todoController = TextEditingController();
    // Use context directly as it's available in the state class
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color?.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        // Use MediaQuery.of(context) instead of ctx if needed for consistency
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Add New Todo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: todoController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Todo Title',
                  hintText: 'What needs to be done?',
                ),
                onSubmitted: (_) {
                  if (todoController.text.isNotEmpty) {
                    todoProvider.addTodo(todoController.text);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Todo'),
                onPressed: () {
                  if (todoController.text.isNotEmpty) {
                    todoProvider.addTodo(todoController.text);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Navigate to Add/Edit screen (from NoteListScreen)
  void _navigateToAddEditNote(BuildContext context, Note? note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(note: note),
        fullscreenDialog: true,
      ),
    );
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    // ThemeProvider is not directly accessed here anymore for actions (moved to SettingsScreen)

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        actions: [
          // Settings Button
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      // Use AnimatedSwitcher for smooth transition between screens
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300), // Animation duration
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Use FadeTransition for a simple fade effect
          return FadeTransition(opacity: animation, child: child);
        },
        // Key is important to tell AnimatedSwitcher which child is displayed
        child: Center(
          key: ValueKey<int>(_selectedIndex), // Use selectedIndex as the key
          // Display the widget corresponding to the selected index
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: const Icon(
              Icons.check_circle,
            ), // Filled icon when active
            label: 'Todos',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.note_alt_outlined),
            activeIcon: const Icon(Icons.note_alt), // Filled icon when active
            label: 'Notes',
          ),
        ],
        currentIndex: _selectedIndex,
        // Use theme color for selected item
        // selectedItemColor: Theme.of(context).colorScheme.secondary,
        onTap: _onItemTapped,
        // Use theme for background and unselected color
        // backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        // unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        type:
            BottomNavigationBarType.fixed, // Ensures labels are always visible
      ),
      floatingActionButton: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale:
            1.0, // Always visible for now, could be tied to _selectedIndex later
        child: FloatingActionButton(
          onPressed: () {
            if (_selectedIndex == 0) {
              // Add Todo action
              _showAddTodoDialog(context);
            } else if (_selectedIndex == 1) {
              // Add Note action
              _navigateToAddEditNote(context, null);
            }
          },
          tooltip: _selectedIndex == 0 ? 'Add Todo' : 'Add Note',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
