// --- シュレッダー画面 ---
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import '../models/task.dart';
import 'package:flutter/material.dart';
import 'package:to_do/models/particle.dart';
import 'package:to_do/widgets/shredder_painter.dart';

class ShredderPage extends StatefulWidget {
  final Task task; //StringではなくTask型に変更
  const ShredderPage({super.key, required this.task});

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
                tag: 'task_${widget.task.id}',
                child: Material(
                  elevation: 10,
                  child: Container(
                    width: 300, height: 400, color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.task.title, // widget.task.title を表示
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)
                    ),
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