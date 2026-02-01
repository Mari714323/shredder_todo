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
  // String のリストから Task のリストに変更
  List<Task> _tasks = [];
  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks(); // 起動時にデータを読み込む
  }

  // データの読み込み
  // --- 読み込みの修正 ---
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? taskStringList = prefs.getStringList('tasks');
    
    if (taskStringList != null) {
      setState(() {
        // 文字列(JSON)のリストを Task オブジェクトのリストに変換
        _tasks = taskStringList.map((item) => Task.fromJson(item)).toList();
      });
    } else {
      // 初期データも Task オブジェクトで作る
      setState(() {
        _tasks = [
          Task(id: '1', title: 'ブログ記事を書く', dueDate: DateTime.now()),
          Task(id: '2', title: 'Flutterの勉強', dueDate: DateTime.now()),
        ];
      });
    }
  }
  // データの保存
  // --- 保存の修正 ---
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    // Task オブジェクトを JSON 文字列に変換してリスト化
    final List<String> taskStringList = _tasks.map((task) => task.toJson()).toList();
    await prefs.setStringList('tasks', taskStringList);
  }

  // 引数に日付と優先度を追加
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
      Navigator.pop(context); // ダイアログを閉じる
    }
  }

  void _showAddTaskDialog() {
    // ダイアログ内での一時的な状態
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TaskPriority selectedPriority = TaskPriority.medium;

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder を使うとダイアログ内で「再描画」ができるようになります
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新しいタスクを追加'),
              content: SingleChildScrollView( // 画面からはみ出さないように
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _textFieldController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: "タスク名"),
                    ),
                    const SizedBox(height: 20),
                    
                    // --- 期限の選択 ---
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
                          // ダイアログ内の表示を更新
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),

                    // --- 優先度の選択 ---
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 追加ボタンを押した時に、選択した値を渡してタスク作成
                    _addTask(selectedDate, selectedPriority);
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 画面遷移の指示だけを行う
  // --- 遷移の修正 ---
  void _navigateToShredder(int index) async {
    final selectedTask = _tasks[index];

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            ShredderPage(task: selectedTask), // taskText ではなく task を渡す！
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    setState(() {
      _tasks.removeAt(index);
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
      appBar: AppBar(title: const Text('シュレッダー ToDo')),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Hero(
            tag: 'task_${task.id}', // ID を使うことで重複エラーを防ぐ！
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(task.title), // .title を指定して表示
                subtitle: Text('期限: ${task.dueDate.year}/${task.dueDate.month}/${task.dueDate.day}'), // 期限を表示
                trailing: const Icon(Icons.check_circle_outline),
                onTap: () => _navigateToShredder(index),
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