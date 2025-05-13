import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'note.g.dart'; // Hive generator will create this file

@HiveType(typeId: 1) // Unique typeId for Hive (different from Todo)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content; // Store Quill delta as JSON String

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  Note({
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? id,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now() {
    this.id = id ?? const Uuid().v4();
  }
}
