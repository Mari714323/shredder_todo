import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shredder ToDo',
      theme: ThemeData(
        primaryColor: Colors.blue,
        useMaterial3: true,
      ),
      home: const TodoListPage(),
    );
  }
}

// --- リスト画面 ---
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}
class _TodoListPageState extends State<TodoListPage> {
  List<String> _tasks = [];
  final TextEditingController _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks(); // 起動時にデータを読み込む
  }

  // データの読み込み
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = prefs.getStringList('tasks') ?? [];
    });
  }
  // データの保存
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasks', _tasks);
  }

  void _addTask() {
    if (_textFieldController.text.isNotEmpty) {
      setState(() {
        _tasks.add(_textFieldController.text);
      });
      _saveTasks(); // 追加した後に保存
      _textFieldController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新しいタスクを追加'),
          content: TextField(
            controller: _textFieldController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "何をする？"),
            onSubmitted: (value) => _addTask(),
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
              onPressed: _addTask,
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }

  // 画面遷移の指示だけを行う
  void _navigateToShredder(int index) async {
    final taskText = _tasks[index];

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ShredderPage(taskText: taskText),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // シュレッダー画面から戻ってきたら削除
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
            tag: 'task_$task',
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(task),
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

// --- パーティクル（紙くず）モデル ---
class Particle {
  double x, y, vx, vy, angle, va;
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.angle, required this.va});

  void update() {
    x += vx;
    y += vy;
    vy += 0.2; // 重力
    angle += va;
  }
}

class ShreddedPaperPainter extends CustomPainter {
  final List<Particle> particles;
  ShreddedPaperPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.y * 0.05);
      canvas.drawRect(Rect.fromLTWH(0, 0, 4, 12), paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// --- シュレッダー画面 ---
class ShredderPage extends StatefulWidget {
  final String taskText;
  const ShredderPage({super.key, required this.taskText});

  @override
  State<ShredderPage> createState() => _ShredderPageState();
}

class _ShredderPageState extends State<ShredderPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  final AudioPlayer _audioPlayer = AudioPlayer(); // ここでプレイヤーを定義
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  bool _isShredding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
      if (_isShredding) {
        _updateParticles();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pop();
      }
    });
  }

  void _updateParticles() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      if (_controller.value > 0.1 && _controller.value < 0.9) {
        for (int i = 0; i < 3; i++) {
          _particles.add(Particle(
            x: screenWidth / 2 + (_random.nextDouble() * 180 - 90),
            y: screenHeight - 150,
            vx: _random.nextDouble() * 4 - 2,
            vy: _random.nextDouble() * 2 + 1,
            angle: _random.nextDouble() * math.pi,
            va: _random.nextDouble() * 0.2,
          ));
        }
      }
      for (var p in _particles) { p.update(); }
      _particles.removeWhere((p) => p.y > screenHeight);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _audioPlayer.dispose(); // 忘れずに破棄
    super.dispose();
  }

  // ここに音の再生とアニメーション開始をまとめる
  void _startShredding() async {
    setState(() => _isShredding = true);
    
    // 音を鳴らす（ファイルがない場合はエラーを無視して進む）
    try {
      await _audioPlayer.play(AssetSource('sounds/shredder.mp3'));
    } catch (e) {
      debugPrint("Sound file not found, skipping: $e");
    }

    _controller.forward();
    _particleController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      body: Stack(
        children: [
          // 1. 紙（奥）
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double slideDown = _controller.value * 600;
                return Transform.translate(offset: Offset(0, slideDown), child: child);
              },
              child: Hero(
                tag: 'task_${widget.taskText}',
                child: Material(
                  elevation: 10,
                  child: Container(
                    width: 300, height: 400, color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Text(widget.taskText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ),
            ),
          ),
          // 2. 箱と壁（真ん中）
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isShredding)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: ElevatedButton.icon(
                      onPressed: _startShredding,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('！完了！'),
                    ),
                  ),
                Container(
                  width: double.infinity, height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey[800]!, // 上は少し明るく
                        Colors.grey[900]!, // 下は暗く
                      ],
                    ),
                    border: const Border(
                      top: BorderSide(color: Colors.black, width: 8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, -5), // 上方向に影を出して立体感を出す
                      ),
                    ],
                  ),
                  child: const Icon(Icons.waves, color: Colors.white10, size: 80),
                ),
                Container(width: double.infinity, height: 200, color: Colors.black),
              ],
            ),
          ),
          // 3. 紙くず（手前）
          IgnorePointer(
            child: CustomPaint(
              painter: ShreddedPaperPainter(_particles),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}