import 'package:flutter/material.dart';
import '../services/goal_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _goalController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSaved = false;
  String _lastSavedValue = '';

  @override
  void initState() {
    super.initState();
    _loadGoalSteps();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // フォーカスが外れたら自動保存
    if (!_focusNode.hasFocus) {
      _autoSave();
    }
  }

  Future<void> _loadGoalSteps() async {
    final goal = await GoalService.getGoalSteps();
    setState(() {
      _goalController.text = goal.toString();
      _lastSavedValue = goal.toString();
    });
  }

  Future<void> _autoSave() async {
    final text = _goalController.text.trim();
    if (text == _lastSavedValue) return; // 変更がなければスキップ
    
    final steps = int.tryParse(text);
    if (steps != null && steps > 0) {
      await GoalService.setGoalSteps(steps);
      _lastSavedValue = text;
      _showSavedIndicator();
    }
  }

  Future<void> _setGoalAndSave(int steps) async {
    setState(() {
      _goalController.text = steps.toString();
    });
    
    if (_lastSavedValue == steps.toString()) return;
    
    await GoalService.setGoalSteps(steps);
    _lastSavedValue = steps.toString();
    _showSavedIndicator();
  }

  void _showSavedIndicator() {
    setState(() {
      _showSaved = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSaved = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 画面タップでフォーカス解除
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'カスタマイズ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Settings',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    // 保存インジケーター
                    AnimatedOpacity(
                      opacity: _showSaved ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              size: 14,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '保存しました',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // 目標歩数設定カード
                    Container(
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
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.flag_outlined,
                                    color: colorScheme.secondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '1日の目標歩数',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '入力後、自動で保存されます',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 1,
                            color: Colors.grey.shade100,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: TextField(
                              controller: _goalController,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _autoSave(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1,
                              ),
                              decoration: InputDecoration(
                                hintText: '8000',
                                hintStyle: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                ),
                                suffixText: '歩',
                                suffixStyle: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[500],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: colorScheme.secondary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 推奨目標カード
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: colorScheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '推奨目標（タップで即保存）',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _GoalSuggestion(
                            label: '健康維持',
                            steps: 8000,
                            isSelected: _goalController.text == '8000',
                            color: colorScheme.secondary,
                            onTap: () => _setGoalAndSave(8000),
                          ),
                          const SizedBox(height: 8),
                          _GoalSuggestion(
                            label: 'アクティブ',
                            steps: 10000,
                            isSelected: _goalController.text == '10000',
                            color: colorScheme.secondary,
                            onTap: () => _setGoalAndSave(10000),
                          ),
                          const SizedBox(height: 8),
                          _GoalSuggestion(
                            label: 'チャレンジ',
                            steps: 15000,
                            isSelected: _goalController.text == '15000',
                            color: colorScheme.secondary,
                            onTap: () => _setGoalAndSave(15000),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalSuggestion extends StatelessWidget {
  final String label;
  final int steps;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _GoalSuggestion({
    required this.label,
    required this.steps,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
            Text(
              '${_formatNumber(steps)}歩',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[600],
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
