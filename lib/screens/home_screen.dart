import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../services/health_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 状態管理
  HealthStatus _healthStatus = HealthStatus.loading;
  int _todaySteps = 0;
  int _goalSteps = GoalService.defaultGoal;

  // 計算用
  double get _distance => _todaySteps * 0.0008;
  double get _calories => _todaySteps * 0.04;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadGoalSteps();
  }

  Future<void> _initialize() async {
    await _loadGoalSteps();
    await _checkAndFetchSteps();
  }

  Future<void> _loadGoalSteps() async {
    final goal = await GoalService.getGoalSteps();
    if (mounted) {
      setState(() {
        _goalSteps = goal;
      });
    }
  }

  Future<void> _checkAndFetchSteps() async {
    setState(() {
      _healthStatus = HealthStatus.loading;
    });

    // 権限チェック
    final hasAuth = await HealthService.hasAuthorization();
    
    if (!hasAuth) {
      // 権限がない場合はリクエスト
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

    // 歩数取得
    await _fetchSteps();
  }

  Future<void> _fetchSteps() async {
    final steps = await HealthService.getTodaySteps();
    if (mounted) {
      setState(() {
        if (steps != null) {
          _todaySteps = steps;
          _healthStatus = HealthStatus.authorized;
        } else {
          _healthStatus = HealthStatus.error;
        }
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _healthStatus = HealthStatus.loading;
    });
    
    final granted = await HealthService.requestAuthorization();
    if (granted) {
      await _fetchSteps();
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
            ? _buildLoading(theme)
            : _healthStatus == HealthStatus.notAuthorized
                ? _buildPermissionRequest(theme, colorScheme)
                : _buildContent(theme, colorScheme),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '歩数を取得中...',
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
            '歩数データを取得するために\nヘルスケアへのアクセスを許可してください',
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
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final remainingSteps = _goalSteps - _todaySteps;
    final progress = _todaySteps / _goalSteps;

    return RefreshIndicator(
      onRefresh: _fetchSteps,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日のアクティビティ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),

            // 円形プログレス + 歩数
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背景リング
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CustomPaint(
                        painter: _RingPainter(
                          progress: 1.0,
                          color: Colors.grey.shade200,
                          strokeWidth: 16,
                        ),
                      ),
                    ),
                    // プログレスリング
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CustomPaint(
                        painter: _RingPainter(
                          progress: progress > 1.0 ? 1.0 : progress,
                          color: colorScheme.secondary,
                          strokeWidth: 16,
                        ),
                      ),
                    ),
                    // 中央の歩数表示
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatNumber(_todaySteps),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '歩',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[500],
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 達成率
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '目標の ${(progress * 100).toStringAsFixed(0)}% 達成',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // ステータスカード
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
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
                  Expanded(
                    child: _StatItem(
                      icon: Icons.straighten,
                      label: '距離',
                      value: '${_distance.toStringAsFixed(1)}',
                      unit: 'km',
                      color: colorScheme.secondary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.local_fire_department_outlined,
                      label: 'カロリー',
                      value: '${_calories.toStringAsFixed(0)}',
                      unit: 'kcal',
                      color: colorScheme.secondary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.flag_outlined,
                      label: '残り',
                      value: _formatNumber(remainingSteps > 0 ? remainingSteps : 0),
                      unit: '歩',
                      color: Colors.grey[600]!,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 目標カード
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '本日の目標',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatNumber(_goalSteps)} 歩',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
