import 'dart:io'; // For Platform.isAndroid
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:provider/provider.dart';
import 'package:todo/providers/note_provider.dart';
import 'package:todo/providers/theme_provider.dart';
import 'package:todo/providers/todo_provider.dart';
import 'package:todo/services/storage_service.dart';
import 'package:todo/screens/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Permission request moved to HomeScreen initState

  // Initialize Hive and open boxes via StorageService
  await StorageService.instance.init();

  // Initialize ThemeProvider early to load preference before build
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define Light Theme
    final ThemeData lightTheme = ThemeData.light().copyWith(
      primaryColor: Colors.teal,
      scaffoldBackgroundColor: Colors.grey[100], // Light grey background
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.teal, // Teal AppBar
        elevation: 1,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
        primary: Colors.teal,
        secondary: Colors.orangeAccent, // Different accent for light theme
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey[600],
        elevation: 5,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.teal; // Color when checked
          }
          return Colors.grey; // Color when unchecked
        }),
        checkColor: WidgetStateProperty.all(
          Colors.white,
        ), // Color of the check mark
        side: BorderSide(color: Colors.grey.shade400), // Border color
      ),
      useMaterial3: true,
    );

    // Define Dark Theme (using previous definition)
    final ThemeData darkTheme = ThemeData.dark().copyWith(
      primaryColor: Colors.tealAccent,
      scaffoldBackgroundColor: const Color(0xFF1F1F1F),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2A2A2A), // Slightly lighter AppBar
        elevation: 0, // Flat design
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.tealAccent),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
        primary: Colors.teal,
        secondary: Colors.tealAccent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2A2A2A),
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        elevation: 5,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2A2A2A),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.tealAccent;
          }
          return Colors.grey;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: BorderSide(color: Colors.grey.shade600),
      ),
      useMaterial3: true,
    );

    // Use MultiProvider to provide multiple providers down the widget tree
    return MultiProvider(
      providers: [
        // ThemeProvider is already provided above MyApp
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      // Consume ThemeProvider to apply the theme
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Todo & Notes App',
            themeMode: themeProvider.themeMode, // Use theme mode from provider
            theme: lightTheme, // Provide light theme
            darkTheme: darkTheme, // Provide dark theme
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
