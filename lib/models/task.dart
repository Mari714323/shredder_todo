import 'dart:convert';

// 優先度を定義する列挙型（Enum）
enum TaskPriority { high, medium, low }

class Task {
  final String id;         // タスクを一意に識別するためのID
  String title;            // タスクの内容
  DateTime dueDate;        // 締め切り日
  TaskPriority priority;   // 優先度
  bool isCompleted;        // 完了したかどうか

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.priority = TaskPriority.medium, // デフォルトは「中」
    this.isCompleted = false,            // 最初は未完了
  });

  // --- データの保存・読み込み用の変換ロジック ---

  // TaskオブジェクトをMap型（辞書形式）に変換する
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.toIso8601String(), // 日付は文字列として保存
      'priority': priority.index,           // Enumは数字（0,1,2）として保存
      'isCompleted': isCompleted,
    };
  }

  // Map型からTaskオブジェクトを再構築する
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      dueDate: DateTime.parse(map['dueDate']),
      priority: TaskPriority.values[map['priority']],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  // JSON形式の文字列に変換する
  String toJson() => json.encode(toMap());

  // JSON形式の文字列からTaskオブジェクトを作る
  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}