import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/models/todo.dart';
import 'package:todo/providers/todo_provider.dart';
// We might need a separate screen/dialog for adding/editing later
// import 'package:todo/screens/add_edit_todo_screen.dart';

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  // Function to show the Add Todo Dialog/Modal
  void _showAddTodoDialog(BuildContext context) {
    final TextEditingController todoController = TextEditingController();
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows the sheet to take full height if needed
      backgroundColor: Theme.of(context).cardTheme.color?.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          // Adjust padding based on keyboard visibility
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take only necessary height
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
                  // Allow submitting with keyboard action
                  if (todoController.text.isNotEmpty) {
                    todoProvider.addTodo(todoController.text);
                    Navigator.of(ctx).pop(); // Close the bottom sheet
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50), // Full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Todo'),
                onPressed: () {
                  if (todoController.text.isNotEmpty) {
                    todoProvider.addTodo(todoController.text);
                    Navigator.of(ctx).pop(); // Close the bottom sheet
                  }
                },
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in TodoProvider
    return Scaffold(
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          final todos = todoProvider.todos;

          if (todos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_box_outline_blank,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No todos yet!',
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

          // Display todos in a ListView
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return _buildTodoItem(context, todo, todoProvider);
            },
          );
        },
      ),
      // FAB removed - will be handled by HomeScreen
    );
  }

  // Helper widget to build each Todo item with modern styling
  Widget _buildTodoItem(
    BuildContext context,
    Todo todo,
    TodoProvider provider,
  ) {
    return Dismissible(
      key: Key(todo.id), // Unique key for Dismissible
      direction: DismissDirection.endToStart, // Swipe from right to left
      onDismissed: (direction) {
        provider.softDeleteTodo(todo.id); // Changed to softDeleteTodo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${todo.title} moved to trash'), // Updated message
            // action: SnackBarAction(label: 'UNDO', onPressed: () { /* Undo logic */ }),
          ),
        );
      },
      background: Container(
        color: Colors.redAccent.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
      ),
      child: Card(
        // Using CardTheme defined in main.dart
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          leading: Checkbox(
            value: todo.isDone,
            onChanged: (bool? value) {
              provider.toggleTodoStatus(todo.id);
            },
            // Using CheckboxTheme defined in main.dart
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isDone ? TextDecoration.lineThrough : null,
              color:
                  todo.isDone
                      ? Colors.grey
                      : Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.redAccent.withOpacity(0.8),
            ),
            tooltip: 'Delete Todo',
            onPressed: () {
              // Optional: Show confirmation dialog before deleting via button
              showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Delete Todo?'),
                      content: Text(
                        'Are you sure you want to delete "${todo.title}"?',
                      ),
                      backgroundColor: Theme.of(context).cardTheme.color,
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                          child: const Text(
                            'Move to Trash',
                          ), // Updated button text
                          onPressed: () {
                            provider.softDeleteTodo(
                              todo.id,
                            ); // Changed to softDeleteTodo
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ],
                    ),
              );
            },
          ),
          // Optional: Add onTap for editing
          // onTap: () => _showEditTodoDialog(context, todo),
        ), // End ListTile
      ), // End Card
    ); // End Dismissible
  }
}
