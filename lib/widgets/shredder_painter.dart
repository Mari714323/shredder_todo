import 'package:flutter/material.dart';
import 'package:to_do/models/particle.dart';

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