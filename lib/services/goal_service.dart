import 'package:shared_preferences/shared_preferences.dart';

class GoalService {
  static const String _goalKey = 'goal_steps';
  static const int defaultGoal = 8000;

  static Future<int> getGoalSteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? defaultGoal;
  }

  static Future<void> setGoalSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, steps);
  }
}
