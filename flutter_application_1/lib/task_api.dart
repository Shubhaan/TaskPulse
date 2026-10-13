import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task_item.dart';

class TaskApi {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<List<TaskItem>> getTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/tasks'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Added <TaskItem> and userId to fix the map/model errors
      return data.map<TaskItem>((json) => TaskItem(
        id: json['id'],
        title: json['title'],
        category: json['category'],
        time: json['task_time'],
        done: json['done'] == 1,
        date: json['task_date'].toString().split('T')[0],
        userId: json['user_id'] ?? 1,
      )).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<TaskItem> setDone(TaskItem task, bool done) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/${task.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'done': done}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TaskItem(
        id: data['id'],
        title: data['title'],
        category: data['category'],
        time: data['task_time'],
        done: data['done'] == 1,
        date: data['task_date'].toString().split('T')[0],
        userId: data['user_id'] ?? 1,
      );
    } else {
      throw Exception('Failed to update task');
    }
  }

  Future<TaskItem> addTask(String title, String category, String time, String date) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'category': category,
        'task_time': time,
        'task_date': date,
        'user_id': 1
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TaskItem(
        id: data['id'],
        title: data['title'],
        category: data['category'],
        time: data['task_time'],
        done: data['done'] == 1,
        date: data['task_date'].toString().split('T')[0],
        userId: data['user_id'] ?? 1,
      );
    } else {
      throw Exception('Failed to add task');
    }
  }

  // Added this to fix the error coming from calendar_page.dart
  void close() {}
}