import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // モックデータ（過去7日分）
  static const List<Map<String, dynamic>> mockHistory = [
    {'day': '月', 'steps': 5234},
    {'day': '火', 'steps': 6789},
    {'day': '水', 'steps': 4321},
    {'day': '木', 'steps': 8901},
    {'day': '金', 'steps': 3456},
    {'day': '土', 'steps': 12345},
    {'day': '日', 'steps': 4321},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴'),
      ),
      body: ListView.builder(
        itemCount: mockHistory.length,
        itemBuilder: (context, index) {
          final item = mockHistory[index];
          return ListTile(
            title: Text(
              '${item['day']}曜日',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              '${item['steps']}歩',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
