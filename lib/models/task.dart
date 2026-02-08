import 'dart:convert';

// 優先度を定義する列挙型（Enum）
enum TaskPriority { high, medium, low }

class Task {
  final String id;         
  String title;            
  DateTime dueDate;        
  TaskPriority priority;   
  bool isCompleted;        
  int colorValue; // 【追加】付箋の色（ARGB値）を保存する変数

  // 【追加】付箋の色の選択肢を定数として定義しておきます
  static const List<int> stickyNoteColors = [
    0xFFFFF9C4, // 黄色 (Yellow 100)
    0xFFB3E5FC, // 水色 (Light Blue 100)
    0xFFC8E6C9, // 薄緑 (Green 100)
    0xFFF8BBD0, // ピンク (Pink 100)
  ];

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.colorValue = 0xFFFFF9C4, // 【追加】デフォルトは黄色
  });

  // --- データの保存・読み込み用の変換ロジック ---

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.index,
      'isCompleted': isCompleted,
      'colorValue': colorValue, // 【追加】
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      dueDate: DateTime.parse(map['dueDate']),
      priority: TaskPriority.values[map['priority']],
      isCompleted: map['isCompleted'] ?? false,
      colorValue: map['colorValue'] ?? 0xFFFFF9C4, // 【追加】データがない場合は黄色にする
    );
  }

  String toJson() => json.encode(toMap());
  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}