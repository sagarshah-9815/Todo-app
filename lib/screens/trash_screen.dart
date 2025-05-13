import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todo/providers/todo_provider.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final trashedTodos = todoProvider.trashedTodos;

    // Sort by deletedAt, newest first (if available)
    trashedTodos.sort((a, b) {
      if (a.deletedAt == null && b.deletedAt == null) return 0;
      if (a.deletedAt == null) return 1; // Nulls last
      if (b.deletedAt == null) return -1; // Nulls last
      return b.deletedAt!.compareTo(a.deletedAt!);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash - Todos'),
        // Potentially add "Empty Trash" button later
      ),
      body:
          trashedTodos.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Trash is empty',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: trashedTodos.length,
                itemBuilder: (context, index) {
                  final todo = trashedTodos[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        todo.title,
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle:
                          todo.deletedAt != null
                              ? Text(
                                'Deleted: ${DateFormat.yMd().add_jm().format(todo.deletedAt!)}',
                              )
                              : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore_from_trash_outlined),
                            tooltip: 'Restore',
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              todoProvider.restoreTodo(todo.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${todo.title}" restored'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever_outlined),
                            tooltip: 'Delete Permanently',
                            color: Theme.of(context).colorScheme.error,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Delete Permanently?'),
                                      content: Text(
                                        'Are you sure you want to permanently delete "${todo.title}"? This action cannot be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                todoProvider.permanentlyDeleteTodo(todo.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '"${todo.title}" permanently deleted',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
