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