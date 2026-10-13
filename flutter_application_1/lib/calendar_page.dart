import 'package:flutter/material.dart';
import 'task_api.dart';
import 'task_item.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TaskApi _api = TaskApi();
  List<TaskItem> _allTasks = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  final Color _brandBlue = const Color(0xFF1E5BBF);

  @override
  void initState() {
    super.initState();
    _loadAllTasks();
  }

  Future<void> _loadAllTasks() async {
    try {
      final tasks = await _api.getTasks();
      setState(() {
        _allTasks = tasks;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleTask(TaskItem task) async {
    final updated = await _api.setDone(task, !task.done);
    setState(() {
      final index = _allTasks.indexWhere((t) => t.id == task.id);
      if (index >= 0) _allTasks[index] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter tasks based on the currently selected calendar date
    final selectedTasks = _allTasks.where((t) {
      try {
        final taskDate = DateTime.parse(t.date);
        return taskDate.year == _selectedDate.year &&
               taskDate.month == _selectedDate.month &&
               taskDate.day == _selectedDate.day;
      } catch (e) {
        return false; // Safely ignore formatting errors
      }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2B5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calendar',
          style: TextStyle(color: Color(0xFF0F2B5B), fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Native Flutter Calendar Widget
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    onDateChanged: (DateTime newDate) {
                      setState(() {
                        _selectedDate = newDate;
                      });
                    },
                  ),
                ),
                
                // Tasks header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scheduled Tasks',
                        style: TextStyle(color: Color(0xFF0F2B5B), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${selectedTasks.length} tasks',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Task List for Selected Date
                Expanded(
                  child: selectedTasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tasks scheduled for this day.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: selectedTasks.length,
                          itemBuilder: (context, index) {
                            final task = selectedTasks[index];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: IconButton(
                                  icon: Icon(
                                    task.done ? Icons.check_circle : Icons.circle_outlined,
                                    color: task.done ? _brandBlue : Colors.grey,
                                  ),
                                  onPressed: () => _toggleTask(task),
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: task.done ? TextDecoration.lineThrough : null,
                                    color: task.done ? Colors.grey : const Color(0xFF0F2B5B),
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(Icons.work_outline, size: 12, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(task.category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(width: 12),
                                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(task.time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}