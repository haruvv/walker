import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // モックデータ
  static const int todaySteps = 4321;
  static const int goalSteps = 8000;

  @override
  Widget build(BuildContext context) {
    final remainingSteps = goalSteps - todaySteps;
    final progress = todaySteps / goalSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '今日の歩数',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$todaySteps',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '目標: $goalSteps歩',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'あと $remainingSteps歩',
              style: TextStyle(
                fontSize: 20,
                color: remainingSteps > 0 ? Colors.grey[700] : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
