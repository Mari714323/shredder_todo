// lib/models/particle.dart の完成形（再掲）
class Particle {
  double x, y, vx, vy, angle, va;
  double targetY; // これを追加！
  bool isSettled = false; 

  Particle({
    required this.x, 
    required this.y, 
    required this.vx, 
    required this.vy, 
    required this.angle, 
    required this.va,
    required this.targetY, // これを追加！
  });

  void update() { // 引数の floorY を消す！
    if (isSettled) return;

    x += vx;
    y += vy;
    vy += 0.15;
    angle += va;

    if (y >= targetY) { // targetY で止まるようにする！
      y = targetY;
      isSettled = true;
      vx = 0;
      vy = 0;
      va = 0;
    }
  }
}