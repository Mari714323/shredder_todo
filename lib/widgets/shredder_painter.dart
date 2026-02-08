import 'package:flutter/material.dart';
import 'package:to_do/models/particle.dart';

class ShreddedPaperPainter extends CustomPainter {
  final List<Particle> particles;
  final Color color; // 【追加】付箋の色を受け取る変数

  // コンストラクタで色を受け取れるように変更
  ShreddedPaperPainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // 渡された色をペイントに使用する
    final paint = Paint()..color = color;

    for (var p in particles) {
      canvas.save();
      // パーティクルの現在位置へ移動
      canvas.translate(p.x, p.y);
      // 回転を加えてヒラヒラ感を出す
      canvas.rotate(p.angle);
      
      // ▼▼▼ 形状を「細長く」調整 ▼▼▼
      // Rect.fromLTWH(左上のx, 左上のy, 幅, 高さ)
      // 幅を2、高さを25くらいにすると「細長いストリップ状」に見えます
      canvas.drawRect(const Rect.fromLTWH(0, 0, 2, 25), paint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}