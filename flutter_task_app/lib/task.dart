import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';


class Task {
  String objectId;  // Add this line
  String title;
  String description;

  Task({required this.objectId, required this.title, required this.description});

  // Factory method to create a Task from a ParseObject
  factory Task.fromParse(ParseObject object) {
    return Task(
      objectId: object.objectId!,
      title: object.get<String>('Title')!,
      description: object.get<String>('Description')!,
    );
  }
}