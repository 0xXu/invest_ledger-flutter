import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../data/models/transaction.dart';
import '../../../data/models/investment_goal.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/investment_goal_provider.dart';
import '../../providers/color_theme_provider.dart';
import '../../widgets/stock_investment_card.dart';
import '../../widgets/goal_progress_card.dart';
import '../../widgets/refresh_button.dart';
import '../../widgets/animated_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true; // 保持页面状态，避免重建

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于保活机制
    final user = ref.watch(userProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final statsAsync = ref.watch(transactionStatsProvider);



    // 如果用户未登录，重新导航到用户选择页面
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/user-selection');
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }



    return Scaffold(
      appBar: AppBar(
        title: Text('投资概览 - ${user.name}'),
        actions: [
          RefreshButton.icon(
            onRefresh: () async {
              // 模拟网络延迟
              await Future.delayed(const Duration(seconds: 1));
              ref.invalidate(transactionNotifierProvider);
              ref.invalidate(transactionStatsProvider);
              ref.invalidate(monthlyGoalProgressProvider);
              ref.invalidate(yearlyGoalProgressProvider);
            },
            loadingMessage: '正在刷新数据...',
            tooltip: '刷新数据',
          ),
          IconButton(
            onPressed: () {
              ref.read(userProvider.notifier).logout();
              context.go('/');
            },
            icon: const Icon(LucideIcons.logOut),
            tooltip: '退出登录',
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) => _DashboardContent(
          transactions: transactions,
          statsAsync: statsAsync,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              RefreshButton.filled(
                onRefresh: () async {
                  ref.invalidate(transactionNotifierProvider);
                  ref.invalidate(transactionStatsProvider);
                },
                label: '重试',
                loadingMessage: '正在重新加载...',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/transactions/add?from=dashboard');
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('添加交易'),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final List<Transaction> transactions;
  final AsyncValue<Map<String, dynamic>> statsAsync;

  const _DashboardContent({
    required this.transactions,
    required this.statsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyProgressAsync = ref.watch(monthlyGoalProgressProvider);
    final yearlyProgressAsync = ref.watch(yearlyGoalProgressProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目标进度卡片
          monthlyProgressAsync.when(
            data: (monthlyProgress) => GoalProgressCard(
              title: '月度目标',
              progress: monthlyProgress,
              onSetGoal: () => _showGoalDialog(context, ref, isMonthly: true),
              onEditGoal: () => _showGoalDialog(context, ref, isMonthly: true),
            ),
            loading: () => const Card(child: SizedBox(height: 120)),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('月度目标加载失败: $error'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          yearlyProgressAsync.when(
            data: (yearlyProgress) => GoalProgressCard(
              title: '年度目标',
              progress: yearlyProgress,
              onSetGoal: () => _showGoalDialog(context, ref, isMonthly: false),
              onEditGoal: () => _showGoalDialog(context, ref, isMonthly: false),
            ),
            loading: () => const Card(child: SizedBox(height: 120)),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('年度目标加载失败: $error'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 投资统计概览
          statsAsync.when(
            data: (stats) => _StatsSummary(stats: stats),
            loading: () => const Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Card(child: SizedBox(height: 100))),
                    SizedBox(width: 12),
                    Expanded(child: Card(child: SizedBox(height: 100))),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Card(child: SizedBox(height: 100))),
                    SizedBox(width: 12),
                    Expanded(child: Card(child: SizedBox(height: 100))),
                  ],
                ),
              ],
            ),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('统计数据加载失败: $error'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 最近交易标题
          Text(
            '最近交易',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // 最近交易列表
          if (transactions.isEmpty)
            const Center(
              child: Text('暂无交易记录'),
            )
          else
            ...transactions.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final transaction = entry.value;
              return AnimatedCard(
                delay: Duration(milliseconds: (index + 4) * 150), // 在其他卡片之后
                animationType: CardAnimationType.fadeSlideIn,
                slideDirection: SlideDirection.fromBottom,
                enableScrollVisibility: false, // 关闭滚动可见性检测
                enableAnimation: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: StockInvestmentCard(
                    transaction: transaction,
                    onTap: () {
                      context.push('/transactions/${transaction.id}');
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, {required bool isMonthly}) {
    showDialog(
      context: context,
      builder: (context) => _GoalSettingDialog(
        isMonthly: isMonthly,
        onSave: (targetAmount, description) async {
          final now = DateTime.now();
          await ref.read(investmentGoalNotifierProvider.notifier).setGoal(
            type: GoalType.profit,
            period: isMonthly ? GoalPeriod.monthly : GoalPeriod.yearly,
            year: now.year,
            month: isMonthly ? now.month : null,
            targetAmount: targetAmount,
            description: description,
          );

          // 刷新相关数据
          if (isMonthly) {
            ref.invalidate(monthlyGoalProgressProvider);
          } else {
            ref.invalidate(yearlyGoalProgressProvider);
          }
        },
      ),
    );
  }
}

class _StatsSummary extends ConsumerWidget {
  final Map<String, dynamic> stats;

  const _StatsSummary({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync = ref.watch(profitLossColorsProvider);

    return colorsAsync.when(
      data: (colors) => AnimatedCardList(
        staggerDelay: const Duration(milliseconds: 100),
        animationType: CardAnimationType.scaleIn,
        enableAnimation: true,
        enableScrollAnimation: false, // 关闭滚动动画，避免复杂性
        children: [
          // 第一行：总盈利和总亏损
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: '总盈利',
                  value: '¥${((stats['totalProfit'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                  icon: LucideIcons.trendingUp,
                  color: colors.getProfitColor(),
                  subtitle: '所有正收益之和',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: '总亏损',
                  value: '¥${((stats['totalLoss'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                  icon: LucideIcons.trendingDown,
                  color: colors.getLossColor(),
                  subtitle: '所有负收益之和',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 第二行：净收益和ROI
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: '净收益',
                  value: '${((stats['netProfit'] as num?)?.toDouble() ?? 0.0) >= 0 ? '+' : ''}¥${((stats['netProfit'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                  icon: ((stats['netProfit'] as num?)?.toDouble() ?? 0.0) >= 0 ? LucideIcons.plus : LucideIcons.minus,
                  color: colors.getColorByValue(((stats['netProfit'] as num?)?.toDouble() ?? 0.0)),
                  subtitle: '盈利 - 亏损',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'ROI',
                  value: '${((stats['roi'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}%',
                  icon: LucideIcons.percent,
                  color: colors.getColorByValue(((stats['roi'] as num?)?.toDouble() ?? 0.0)),
                  subtitle: '投资回报率',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 第三行：交易笔数和胜率
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: '交易笔数',
                  value: '${(stats['transactionCount'] as num?)?.toInt() ?? 0}',
                  icon: LucideIcons.activity,
                  color: const Color(0xFF8B5CF6),
                  subtitle: '总交易数量',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: '胜率',
                  value: '${((stats['winRate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                  icon: LucideIcons.target,
                  color: const Color(0xFF06B6D4),
                  subtitle: '盈利笔数/总笔数',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 第四行：盈亏比
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: '盈亏比',
                  value: ((stats['profitLossRatio'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
                  icon: LucideIcons.scale,
                  color: const Color(0xFFF59E0B),
                  subtitle: '平均盈利/平均亏损',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // 空白占位
            ],
          ),
        ],
      ),
      loading: () => const Column(
        children: [
          Row(
            children: [
              Expanded(child: Card(child: SizedBox(height: 100))),
              SizedBox(width: 12),
              Expanded(child: Card(child: SizedBox(height: 100))),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Card(child: SizedBox(height: 100))),
              SizedBox(width: 12),
              Expanded(child: Card(child: SizedBox(height: 100))),
            ],
          ),
        ],
      ),
      error: (_, __) => const Column(
        children: [
          Row(
            children: [
              Expanded(child: Card(child: SizedBox(height: 100))),
              SizedBox(width: 12),
              Expanded(child: Card(child: SizedBox(height: 100))),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Card(child: SizedBox(height: 100))),
              SizedBox(width: 12),
              Expanded(child: Card(child: SizedBox(height: 100))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25), // 10% opacity
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSettingDialog extends StatefulWidget {
  final bool isMonthly;
  final Function(double targetAmount, String? description) onSave;

  const _GoalSettingDialog({
    required this.isMonthly,
    required this.onSave,
  });

  @override
  State<_GoalSettingDialog> createState() => _GoalSettingDialogState();
}

class _GoalSettingDialogState extends State<_GoalSettingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _targetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('设置${widget.isMonthly ? '月度' : '年度'}目标'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: '目标金额 (¥)',
                hintText: '请输入目标盈利金额',
                prefixIcon: Icon(LucideIcons.target),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入目标金额';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return '请输入有效的数字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述 (可选)',
                hintText: '为这个目标添加描述',
                prefixIcon: Icon(LucideIcons.fileText),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final targetAmount = double.parse(_targetController.text);
              final description = _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim();

              widget.onSave(targetAmount, description);
              Navigator.of(context).pop();
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}