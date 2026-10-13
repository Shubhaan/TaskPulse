import 'package:flutter/material.dart';
import 'task_api.dart';
import 'task_item.dart';
import 'calendar_page.dart'; 

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TaskApi _api = TaskApi();
  List<TaskItem> _tasks = [];
  bool _loading = true;
  String _selectedFilter = 'All';

  final Color _brandBlue = const Color(0xFF1E5BBF);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _api.getTasks();
      final today = DateTime.now(); 
      
      setState(() {
        _tasks = tasks.where((t) {
          final taskDate = DateTime.parse(t.date);
          return taskDate.year == today.year && 
                 taskDate.month == today.month && 
                 taskDate.day == today.day;
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleTask(TaskItem task) async {
    final updated = await _api.setDone(task, !task.done);
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index >= 0) _tasks[index] = updated;
    });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String selectedCategory = 'Work';
    DateTime selectedDate = DateTime.now(); 
    TimeOfDay selectedTime = TimeOfDay.now(); // Defaults to current time
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add New Task', style: TextStyle(color: Color(0xFF0F2B5B))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Task Title'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: ['Work', 'Personal', 'Health'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setDialogState(() => selectedCategory = val!),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Picker Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(), 
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(primary: _brandBlue),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != selectedDate) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text('Change', style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  
                  // Time Picker Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time: ${selectedTime.format(context)}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      TextButton(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(primary: _brandBlue),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != selectedTime) {
                            setDialogState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: Text('Change', style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      Navigator.pop(context); 
                      
                      final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                      final timeStr = selectedTime.format(context);
                      
                      final newTask = await _api.addTask(
                        titleController.text,
                        selectedCategory,
                        timeStr, 
                        dateStr,
                      );
                      
                      final today = DateTime.now();
                      if (selectedDate.year == today.year && selectedDate.month == today.month && selectedDate.day == today.day) {
                        setState(() {
                          _tasks.add(newTask);
                        });
                      }
                    }
                  },
                  child: const Text('Add Task'),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _selectedFilter == 'All' 
        ? _tasks 
        : _tasks.where((t) => t.category == _selectedFilter).toList();
        
    final completedCount = _tasks.where((t) => t.done).length;
    final totalCount = _tasks.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final percentage = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.check, color: _brandBlue, size: 20),
            ),
            const SizedBox(width: 8),
            Text('FlavorDash', style: TextStyle(color: _brandBlue, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: _brandBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarPage()),
              );
            },
          )
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text('Welcome back, Shubhaan', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const Text('Make today\ncount.', style: TextStyle(color: Color(0xFF0F2B5B), fontSize: 32, height: 1.1, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${_getFormattedDate()} • ${totalCount - completedCount} tasks left', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _brandBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('DAILY PROGRESS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                            child: const Icon(Icons.trending_up, color: Colors.white, size: 16),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('You\'re building your goals with FlavorDash', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text('$percentage% complete • $completedCount of $totalCount tasks', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your tasks', style: TextStyle(color: Color(0xFF0F2B5B), fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('$completedCount/$totalCount done', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: ['All', 'Work', 'Personal', 'Health'].map((filter) {
                    final isSelected = filter == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedFilter = filter),
                        selectedColor: _brandBlue,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[700]),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 12),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
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
                              color: task.done ? Colors.grey : const Color(0xFF0F2B5B)
                            )
                          ),
                          subtitle: Row(
                            children: [
                              Icon(Icons.work_outline, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(task.category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(width: 12),
                              Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('Today', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
          ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: _brandBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 1) {
            _showAddTaskDialog(); 
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Today'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(color: _brandBlue, borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, color: Colors.white), SizedBox(width: 4), Text('Add task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Done'),
        ],
      ),
    );
  }
}