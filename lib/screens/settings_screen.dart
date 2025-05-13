import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/providers/theme_provider.dart';
import 'package:todo/screens/trash_screen.dart'; // Import TrashScreen
import 'package:todo/services/storage_service.dart'; // For backup/restore

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // --- Theme Settings ---
          ListTile(
            leading: Icon(
              themeProvider.themeMode == ThemeMode.dark ||
                      (themeProvider.themeMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark)
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            title: const Text('App Theme'),
            subtitle: Text(
              'Current: ${themeProvider.themeMode.toString().split('.').last.capitalize()}',
            ),
            trailing: Switch(
              value:
                  themeProvider.themeMode == ThemeMode.dark ||
                  (themeProvider.themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness ==
                          Brightness.dark),
              onChanged: (value) {
                themeProvider.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
            onTap: () {
              // Allow tapping the whole tile to toggle
              themeProvider.toggleTheme();
            },
          ),
          const Divider(),

          // --- Data Management ---
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup Data'),
            subtitle: const Text('Save your todos and notes to a file'),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting backup...')),
              );
              final result = await StorageService.instance.backupData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result ?? 'Backup completed.'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore_page_outlined),
            title: const Text('Restore Data'),
            subtitle: const Text('Restore data from a backup file'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('Restore Data?'),
                      content: const Text(
                        'This will overwrite current data. It is recommended to restart the app after restoring.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                          ),
                          child: const Text('Restore'),
                        ),
                      ],
                    ),
              );
              if (confirm == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Starting restore... Select backup files.'),
                  ),
                );
                final result = await StorageService.instance.restoreData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result ?? 'Restore process initiated.'),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
          ),
          const Divider(),

          // --- Trash (Placeholder for now) ---
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Trash'),
            subtitle: const Text('View and manage deleted items'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrashScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
