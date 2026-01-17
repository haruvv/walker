import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import '../services/health_service.dart';
import '../services/goal_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DailySteps> _weeklySteps = [];
  int _goalSteps = GoalService.defaultGoal;
  HealthStatus _healthStatus = HealthStatus.loading;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _healthStatus = HealthStatus.loading;
    });

    // 権限チェック
    final hasAuth = await HealthService.hasAuthorization();
    if (!hasAuth) {
      final granted = await HealthService.requestAuthorization();
      if (!granted) {
        if (mounted) {
          setState(() {
            _healthStatus = HealthStatus.notAuthorized;
          });
        }
        return;
      }
    }

    final goal = await GoalService.getGoalSteps();
    final steps = await HealthService.getWeeklySteps();

    if (mounted) {
      setState(() {
        _goalSteps = goal;
        _weeklySteps = steps;
        _healthStatus = HealthStatus.authorized;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _healthStatus = HealthStatus.loading;
    });

    final granted = await HealthService.requestAuthorization();
    if (granted) {
      await _loadData();
    } else {
      if (mounted) {
        setState(() {
          _healthStatus = HealthStatus.notAuthorized;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _healthStatus == HealthStatus.loading
            ? _buildLoading()
            : _healthStatus == HealthStatus.notAuthorized
                ? _buildPermissionRequest(theme, colorScheme)
                : _weeklySteps.isEmpty
                    ? _buildEmpty(theme)
                    : _buildContent(theme, colorScheme),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '履歴を取得中...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 40,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ヘルスケアの許可が必要です',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '歩数を表示するために\nヘルスケアへのアクセスを許可してください',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                '許可する',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => AppSettings.openAppSettings(),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: colorScheme.primary),
              ),
              child: const Text(
                '設定を開く',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '履歴データがありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final maxSteps = _weeklySteps.isNotEmpty
        ? _weeklySteps.map((e) => e.steps).reduce((a, b) => a > b ? a : b)
        : 1;
    final weekTotal = _weeklySteps.fold(0, (sum, e) => sum + e.steps);
    final dailyAverage = _weeklySteps.isNotEmpty
        ? weekTotal ~/ _weeklySteps.length
        : 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '週間レポート',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'History',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // サマリーカード
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.secondary,
                    colorScheme.secondary.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '週間合計',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatNumber(weekTotal),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          '歩',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '1日平均',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatNumber(dailyAverage),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          '歩',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 履歴リスト
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _weeklySteps.length,
              itemBuilder: (context, index) {
                final item = _weeklySteps[index];
                final steps = item.steps;
                final progress = maxSteps > 0 ? steps / maxSteps : 0.0;
                final isGoalAchieved = steps >= _goalSteps;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 日付表示
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isGoalAchieved
                                ? colorScheme.secondary.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.dayOfWeek,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isGoalAchieved
                                      ? colorScheme.secondary
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                item.dateString,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isGoalAchieved
                                      ? colorScheme.secondary.withOpacity(0.7)
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 歩数とバー
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatNumber(steps),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (isGoalAchieved)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 12,
                                            color: colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '達成',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isGoalAchieved
                                        ? colorScheme.secondary
                                        : colorScheme.secondary.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
