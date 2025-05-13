import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'todo.g.dart'; // Hive generator will create this file

@HiveType(typeId: 0) // Unique typeId for Hive
class Todo extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isDone;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4) // New field for soft delete
  bool isDeleted;

  @HiveField(5) // New field for deletion timestamp
  DateTime? deletedAt;

  Todo({
    required this.title,
    this.isDone = false,
    this.isDeleted = false, // Default to not deleted
    this.deletedAt,
    DateTime? createdAt, // Optional createdAt
    String? id, // Optional id
  }) : createdAt = createdAt ?? DateTime.now() {
    // Default to now if not provided
    this.id = id ?? const Uuid().v4(); // Generate UUID if not provided
  }

  // Method to toggle the done status
  void toggleDone() {
    isDone = !isDone;
  }
}
