// --- リスト画面 ---
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'package:to_do/pages/shredder_page.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}
class _TodoListPageState extends State<TodoListPage> {
  // --- 1. 変数の宣言は1回だけ ---
  List<Task> _tasks = [];
  TaskPriority? _selectedFilter; 
  final TextEditingController _textFieldController = TextEditingController();

  // --- 2. ゲッターを正しく閉じる ---
  List<Task> get _filteredTasks {
    if (_selectedFilter == null) {
      return _tasks;
    }
    return _tasks.where((task) => task.priority == _selectedFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // --- データの読み込み・保存・追加 ---
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? taskStringList = prefs.getStringList('tasks');
    
    if (taskStringList != null) {
      setState(() {
        _tasks = taskStringList.map((item) => Task.fromJson(item)).toList();
      });
    } else {
      setState(() {
        _tasks = [
          Task(id: '1', title: 'ブログ記事を書く', dueDate: DateTime.now()),
          Task(id: '2', title: 'Flutterの勉強', dueDate: DateTime.now()),
        ];
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskStringList = _tasks.map((task) => task.toJson()).toList();
    await prefs.setStringList('tasks', taskStringList);
  }

  void _addTask(DateTime dueDate, TaskPriority priority) {
    if (_textFieldController.text.isNotEmpty) {
      setState(() {
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _textFieldController.text,
          dueDate: dueDate,
          priority: priority,
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
      case TaskPriority.high:
        return Colors.redAccent;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.low:
        return Colors.blueAccent;
    }
  }
  void _showAddTaskDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TaskPriority selectedPriority = TaskPriority.medium;

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
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text("優先度"),
                      trailing: DropdownButton<TaskPriority>(
                        value: selectedPriority,
                        items: TaskPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority == TaskPriority.high ? "高" : 
                                        priority == TaskPriority.medium ? "中" : "低"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedPriority = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _textFieldController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () => _addTask(selectedDate, selectedPriority),
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 3. 削除処理をしっかりメソッドの中に含める ---
  void _navigateToShredder(Task task) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            ShredderPage(task: task), 
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // 画面から戻ってきたらここで削除
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    _saveTasks();
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('シュレッダー ToDo'),
        actions: [
          PopupMenuButton<TaskPriority?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (TaskPriority? priority) {
              setState(() {
                _selectedFilter = priority;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text("すべて表示")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: TaskPriority.high, child: Text("優先度：高")),
              const PopupMenuItem(value: TaskPriority.medium, child: Text("優先度：中")),
              const PopupMenuItem(value: TaskPriority.low, child: Text("優先度：低")),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _filteredTasks.length,
        itemBuilder: (context, index) {
          final task = _filteredTasks[index];
          final color = _getPriorityColor(task.priority);

          // --- 期限の判定ロジック ---
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);

          // 期限が今日より前か？（期限切れ）
          final bool isOverdue = taskDate.isBefore(today);
          // 期限が今日か？
          final bool isToday = taskDate.isAtSameMomentAs(today);

          // 文字の色と太さを決定
          TextStyle dateTextStyle = TextStyle(
            fontSize: 12,
            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
            color: isOverdue 
                ? Colors.red          // 期限切れは「赤」
                : (isToday ? Colors.orange : Colors.grey[600]), // 今日は「オレンジ」、未来は「グレー」
          );

          return Hero(
            tag: 'task_${task.id}',
            child: Card(
              // 期限切れの場合は、カード自体の背景を少し赤らめる演出も可能です
              color: isOverdue ? Colors.red[50] : Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(width: 6, color: color),
                    Expanded(
                      child: ListTile(
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            // 期限切れならタイトルも少し目立たせる
                            color: isOverdue ? Colors.red[900] : Colors.black,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              isOverdue ? Icons.warning : Icons.event, 
                              size: 14, 
                              color: dateTextStyle.color
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.dueDate.year}/${task.dueDate.month}/${task.dueDate.day}',
                              style: dateTextStyle, // ここで判定したスタイルを適用
                            ),
                            if (isOverdue) // 期限切れなら警告ラベルを表示
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text('期限切れ！', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        trailing: Icon(Icons.check_circle_outline, color: color),
                        onTap: () => _navigateToShredder(task),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}