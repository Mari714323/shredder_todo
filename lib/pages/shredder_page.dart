import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/task.dart';
import '../models/particle.dart';
import '../widgets/shredder_painter.dart';

class ShredderPage extends StatefulWidget {
  final Task task;
  const ShredderPage({super.key, required this.task});

  @override
  State<ShredderPage> createState() => _ShredderPageState();
}

class _ShredderPageState extends State<ShredderPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  bool _isShredding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
      if (_isShredding) { _updateParticles(); }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  void _updateParticles() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 投入口（黒いスリット）の高さに合わせる (中央より約65px上)
    final double intakeY = screenHeight / 2 - 65; 
    final double baseFloorY = screenHeight / 2 + 130;
    const double mountainHeight = 40.0;
    const double mountainWidth = 120.0;

    setState(() {
      if (_controller.value > 0.3 && _controller.value < 0.9) {
        for (int i = 0; i < 2; i++) {
          double posX = screenWidth / 2 + (_random.nextDouble() * 160 - 80);
          double distanceFromCenter = (posX - screenWidth / 2).abs();
          double offset = mountainHeight * math.exp(-(math.pow(distanceFromCenter, 2)) / (2 * math.pow(mountainWidth / 2, 2)));
          double individualTargetY = baseFloorY - offset;
          individualTargetY += (_random.nextDouble() * 10 - 5);

          _particles.add(Particle(
            x: posX,
            y: intakeY, // 【修正】投入口から生成されるように変更
            vx: _random.nextDouble() * 1.5 - 0.75,
            vy: _random.nextDouble() * 2 + 2,
            angle: _random.nextDouble() * 0.1,
            va: _random.nextDouble() * 0.05,
            targetY: individualTargetY,
          ));
        }
      }
      for (var p in _particles) { p.update(); }
    });
  }

  void _startShredding() async {
    setState(() => _isShredding = true);
    try {
      await _audioPlayer.play(AssetSource('sounds/shredder.mp3'));
    } catch (e) {
      debugPrint("Sound error: $e");
    }
    _controller.forward();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color noteColor = Color(widget.task.colorValue);

    return Scaffold(
      backgroundColor: const Color(0xFFE0E5EC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. 【奥】シュレッダー内部
          Center(
            child: Container(
              width: 300, height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // 2. 【中間】流れてくる付箋
          ClipRect(
            clipper: _PaperSlotClipper(), 
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // 【修正】開始位置(-200)を調整して上部が切れないように
                  double slide = -200 + (_controller.value * 450);
                  return Transform.translate(
                    offset: Offset(0, slide),
                    child: child,
                  );
                },
                child: Hero(
                  tag: 'task_${widget.task.id}',
                  child: Container(
                    width: 200, height: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: noteColor,
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Text(widget.task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),

          // 3. 【前面】シュレッダー本体（レトロ・ガジェット）
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 340, height: 300,
              margin: const EdgeInsets.only(top: 80), // 【修正】本体位置を少し上げ
              decoration: BoxDecoration(
                color: const Color(0xFFF0EAD6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCD6BC), width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  // 投入口（黒いスリット）
                  Container(
                    width: 280, height: 12,
                    margin: const EdgeInsets.symmetric(vertical: 25), // 位置の微調整
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // デジタル表示
                  Container(
                    width: 200, height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9EA78D),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black26, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isShredding ? "SHREDDING..." : "READY 3000",
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2A2E20), letterSpacing: 2),
                    ),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("DATA DESTROYER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ),

          // 4. 【最前面】紙くず（溜まっていく）
          IgnorePointer(
            child: CustomPaint(
              painter: ShreddedPaperPainter(_particles, noteColor), 
              size: Size.infinite,
            ),
          ),

          // 5. 操作ボタン
          if (!_isShredding)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50), // 【修正】余白を広めに
                child: ElevatedButton(
                  onPressed: _startShredding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text("EXECUTE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaperSlotClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    // 【修正】クリップ位置を投入口スリットの位置(中央より約65px上)に合わせる
    return Rect.fromLTWH(0, 0, size.width, size.height / 2 - 65);
  }
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}