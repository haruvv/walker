import 'package:health/health.dart';

enum HealthStatus {
  loading,
  authorized,
  notAuthorized,
  error,
}

class HealthService {
  static final Health _health = Health();
  static final List<HealthDataType> _types = [HealthDataType.STEPS];

  /// 権限をリクエストして結果を返す
  static Future<bool> requestAuthorization() async {
    try {
      // HealthKitの設定
      await _health.configure();
      
      // 権限リクエスト
      final granted = await _health.requestAuthorization(
        _types,
        permissions: [HealthDataAccess.READ],
      );
      return granted;
    } catch (e) {
      return false;
    }
  }

  /// 権限があるかチェック
  static Future<bool> hasAuthorization() async {
    try {
      await _health.configure();
      final status = await _health.hasPermissions(
        _types,
        permissions: [HealthDataAccess.READ],
      );
      return status ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 今日の歩数を取得
  /// データがない場合は0を返し、エラー時のみnullを返す
  static Future<int?> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      
      // 歩数データを取得
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0; // データなしは0歩として扱う
    } catch (e) {
      return null; // 例外時のみエラー
    }
  }

  /// 過去7日分の歩数を取得
  static Future<List<DailySteps>> getWeeklySteps() async {
    try {
      final now = DateTime.now();
      final List<DailySteps> result = [];

      for (int i = 6; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        
        final steps = await _health.getTotalStepsInInterval(date, endOfDay);
        result.add(DailySteps(date: date, steps: steps ?? 0));
      }

      return result;
    } catch (e) {
      return [];
    }
  }
}

/// 日ごとの歩数データ
class DailySteps {
  final DateTime date;
  final int steps;

  DailySteps({required this.date, required this.steps});

  String get dayOfWeek {
    const days = ['月', '火', '水', '木', '金', '土', '日'];
    return days[date.weekday - 1];
  }

  String get dateString => date.day.toString();
}
