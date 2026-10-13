class TaskItem {
  final int id;
  final String title;
  final String category;
  final String time;
  bool done;
  final String date;
  final int userId;

  TaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.time,
    required this.done,
    required this.date,
    required this.userId,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      category: json['category'] ?? 'Personal',
      time: json['task_time'] ?? json['time'] ?? 'Any time',
      done: json['done'] == 1 || json['done'] == true,
      date: json['task_date'] ?? json['date'] ?? '',
      userId: json['user_id'] is int ? json['user_id'] : int.parse((json['user_id'] ?? '1').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'task_time': time,
        'done': done ? 1 : 0,
        'task_date': date,
        'user_id': userId,
      };
}