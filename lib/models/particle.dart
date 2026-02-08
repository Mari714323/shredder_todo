// --- パーティクル（紙くず）モデル ---
class Particle {
  double x, y, vx, vy, angle, va;
  bool isSettled = false; // 【追加】底に溜まって静止したかどうか

  Particle({
    required this.x, 
    required this.y, 
    required this.vx, 
    required this.vy, 
    required this.angle, 
    required this.va
  });

  // 【変更】引数に床の高さ（floorY）を受け取るようにします
  void update(double floorY) {
    // すでに底に溜まっているなら、位置計算をスキップして負荷を下げます
    if (isSettled) return;

    x += vx;
    y += vy;
    vy += 0.15; // 重力（少しふんわり落ちるように調整）
    angle += va;

    // 指定した床の高さに到達したら、その場で止めます
    if (y >= floorY) {
      y = floorY;
      isSettled = true; // 「溜まった状態」にする
      vx = 0; // 横移動も止める
      vy = 0; // 落下も止める
    }
  }
}