import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'shredder_page.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<Task> _tasks = [];
  TaskPriority? _selectedFilter; // 【復活】フィルタ用変数
  final TextEditingController _textFieldController = TextEditingController();

  // 【復活】フィルタリングされたタスクを取得するゲッター
  List<Task> get _filteredTasks {
    if (_selectedFilter == null) return _tasks;
    return _tasks.where((task) => task.priority == _selectedFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? taskStringList = prefs.getStringList('tasks');
    if (taskStringList != null) {
      setState(() {
        _tasks = taskStringList.map((item) => Task.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskStringList = _tasks.map((task) => task.toJson()).toList();
    await prefs.setStringList('tasks', taskStringList);
  }

  void _addTask(DateTime dueDate, TaskPriority priority, int colorValue) {
    if (_textFieldController.text.isNotEmpty) {
      setState(() {
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _textFieldController.text,
          dueDate: dueDate,
          priority: priority,
          colorValue: colorValue,
        );
        _tasks.add(newTask);
      });
      _saveTasks();
      _textFieldController.clear();
      Navigator.pop(context);
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return Colors.redAccent;
      case TaskPriority.medium: return Colors.orangeAccent;
      case TaskPriority.low: return Colors.blueAccent;
    }
  }

  void _showAddTaskDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TaskPriority selectedPriority = TaskPriority.medium;
    int selectedColor = Task.stickyNoteColors[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新しいタスクを追加'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _textFieldController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: "タスク名"),
                    ),
                    const SizedBox(height: 20),
                    // ▼ 色選択UI
                    const Align(alignment: Alignment.centerLeft, child: Text("付箋の色", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: Task.stickyNoteColors.map((colorInt) {
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = colorInt),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: Color(colorInt),
                              shape: BoxShape.circle,
                              border: Border.all(color: selectedColor == colorInt ? Colors.black : Colors.transparent, width: 2),
                            ),
                            child: selectedColor == colorInt ? const Icon(Icons.check, size: 16) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // 【復活】期限選択
                    ListTile(
                      title: const Text("期限"),
                      subtitle: Text("${selectedDate.year}/${selectedDate.month}/${selectedDate.day}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setDialogState(() => selectedDate = picked);
                      },
                    ),
                    // 【復活】優先度選択
                    ListTile(
                      title: const Text("優先度"),
                      trailing: DropdownButton<TaskPriority>(
                        value: selectedPriority,
                        items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p == TaskPriority.high ? "高" : p == TaskPriority.medium ? "中" : "低"))).toList(),
                        onChanged: (value) { if (value != null) setDialogState(() => selectedPriority = value); },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                ElevatedButton(onPressed: () => _addTask(selectedDate, selectedPriority, selectedColor), child: const Text('追加')),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToShredder(Task task) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ShredderPage(task: task),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
    setState(() { _tasks.removeWhere((t) => t.id == task.id); });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('シュレッダー ToDo'),
        actions: [
          // 【復活】フィルタボタン
          PopupMenuButton<TaskPriority?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (priority) => setState(() => _selectedFilter = priority),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text("すべて表示")),
              const PopupMenuItem(value: TaskPriority.high, child: Text("優先度：高")),
              const PopupMenuItem(value: TaskPriority.medium, child: Text("優先度：中")),
              const PopupMenuItem(value: TaskPriority.low, child: Text("優先度：低")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 【復活】水平カレンダー
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                return Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.cyan[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: index == 0 ? Border.all(color: Colors.cyan, width: 2) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(['日', '月', '火', '水', '木', '金', '土'][date.weekday % 7], style: const TextStyle(fontSize: 12)),
                      Text('${date.day}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
          // タスクリスト（付箋デザイン）
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                final priorityColor = _getPriorityColor(task.priority);
                final bool isOverdue = task.dueDate.isBefore(DateTime.now());

                return Hero(
                  tag: 'task_${task.id}',
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _navigateToShredder(task),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(task.colorValue),
                          borderRadius: BorderRadius.circular(4),
                          // ignore: deprecated_member_use
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(4, 4))],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              // ignore: deprecated_member_use
                              Container(width: 4, color: priorityColor.withOpacity(0.5)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isOverdue ? Colors.red[900] : Colors.black87)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.event, size: 14, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Text('${task.dueDate.year}/${task.dueDate.month}/${task.dueDate.day}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.push_pin, size: 20, color: Colors.black26),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddTaskDialog, child: const Icon(Icons.add)),
    );
  }
}