import 'package:flutter/material.dart';
// ▼ 相対パスに書き換えます（package:to_do/... ではなく）
import 'pages/todo_list_page.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
        cardTheme: const CardThemeData( 
          surfaceTintColor: Colors.white,
          elevation: 4,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      // これで TodoListPage が認識されるはずです
      home: const TodoListPage(),
    );
  }
}