import 'package:flutter/material.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/widgets/status_chip.dart';
import '../controllers/dilution_plan_manager.dart';
import '../models/dilution_plan.dart';

/// 割水計画一覧画面
class DilutionPlansScreen extends StatefulWidget {
  /// コンストラクタ
  const DilutionPlansScreen({Key? key}) : super(key: key);

  @override
  State<DilutionPlansScreen> createState() => _DilutionPlansScreenState();
}

class _DilutionPlansScreenState extends State<DilutionPlansScreen> with SingleTickerProviderStateMixin {
  /// Scaffoldキー (ドロワー表示用)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// タブコントローラー
  late TabController _tabController;

  /// 割水計画マネージャー
  final DilutionPlanManager _planManager = DilutionPlanManager();
  
  /// 進行中の計画リスト
  List<DilutionPlan> _activePlans = [];
  
  /// 完了済みの計画リスト
  List<DilutionPlan> _completedPlans = [];
  
  /// 読み込み中フラグ
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 計画データの読み込み
  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _planManager.initialize();
      final activePlans = await _planManager.getActivePlans();
      final completedPlans = await _planManager.getCompletedPlans();

      setState(() {
        _activePlans = activePlans;
        _completedPlans = completedPlans;
        _isLoading = false;
      });
    } catch (e) {
      print('計画データの読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('割水計画'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlans,
            tooltip: '更新',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            tooltip: 'メニュー',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '計画中'),
            Tab(text: '完了済み'),
          ],
        ),
      ),
      endDrawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivePlansTab(),
                _buildCompletedPlansTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/dilution');
        },
        tooltip: '新規割水計算',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 進行中の計画タブを構築
  Widget _buildActivePlansTab() {
    return _activePlans.isEmpty
        ? _buildEmptyState('進行中の割水計画はありません')
        : _buildPlanList(_activePlans, isActive: true);
  }

  /// 完了済みの計画タブを構築
  Widget _buildCompletedPlansTab() {
    return _completedPlans.isEmpty
        ? _buildEmptyState('完了済みの割水計画はありません')
        : _buildPlanList(_completedPlans, isActive: false);
  }

  /// 空の状態を構築
  Widget _buildEmptyState(String message) {
    return RefreshIndicator(
      onRefresh: _loadPlans,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 72,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/dilution');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('新規割水計算'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 計画リストを構築
  Widget _buildPlanList(List<DilutionPlan> plans, {required bool isActive}) {
    // タンク番号でグループ化
    final groupedPlans = <String, List<DilutionPlan>>{};
    
    for (var plan in plans) {
      final tankNumber = plan.result.tankNumber;
      if (!groupedPlans.containsKey(tankNumber)) {
        groupedPlans[tankNumber] = [];
      }
      groupedPlans[tankNumber]!.add(plan);
    }
    
    return RefreshIndicator(
      onRefresh: _loadPlans,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ...groupedPlans.entries.map((entry) {
            final tankNumber = entry.key;
            final tankPlans = entry.value;
            
            return _buildTankSection(tankNumber, tankPlans, isActive: isActive);
          }).toList(),
        ],
      ),
    );
  }

  /// タンクごとのセクションを構築
  Widget _buildTankSection(String tankNumber, List<DilutionPlan> plans, {required bool isActive}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Text(
              'タンク $tankNumber',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const Divider(height: 1),
          ...plans.map((plan) => _buildPlanItem(plan, isActive: isActive)).toList(),
        ],
      ),
    );
  }

  /// 計画アイテムを構築
  Widget _buildPlanItem(DilutionPlan plan, {required bool isActive}) {
    final result = plan.result;
    final expiringSoon = isActive && plan.daysSinceCreation >= 5 && plan.daysSinceCreation < 7;
    final expired = isActive && plan.daysSinceCreation >= 7;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (result.sakeName != null && result.sakeName!.isNotEmpty)
                Expanded(
                  child: Text(
                    result.sakeName!,
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Text('（酒名なし）', style: TextStyle(fontStyle: FontStyle.italic)),
              _buildStatusChip(context, plan, expiringSoon, expired),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              const Icon(Icons.percent, size: 16),
              const SizedBox(width: 4.0),
              Text(
                'アルコール度数: ${result.initialAlcoholPercentage.toStringAsFixed(2)}% → ${result.targetAlcoholPercentage.toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              const Icon(Icons.water_drop, size: 16),
              const SizedBox(width: 4.0),
              Text(
                '追加水量: ${result.waterAmount.toStringAsFixed(2)}L',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              const Icon(Icons.straighten, size: 16),
              const SizedBox(width: 4.0),
              Text(
                '検尺値: ${result.initialDipstick.toStringAsFixed(1)}mm → ${result.finalDipstick.toStringAsFixed(1)}mm',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 4.0),
              Text(
                '計画日: ${Formatters.dateFormat(plan.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8.0),
              if (plan.isCompleted && plan.completedAt != null) ...[
                const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                const SizedBox(width: 4.0),
                Text(
                  '完了日: ${Formatters.dateFormat(plan.completedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 編集機能を実装
                    Navigator.of(context).pushNamed('/dilution');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('編集'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton.icon(
                  onPressed: () => _confirmCompletePlan(plan),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('完了'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// ステータスチップを構築
  Widget _buildStatusChip(
    BuildContext context,
    DilutionPlan plan,
    bool expiringSoon,
    bool expired,
  ) {
    if (plan.isCompleted) {
      return const StatusChip(type: StatusType.completed);
    } else if (expired) {
      return const StatusChip(type: StatusType.expired);
    } else if (expiringSoon) {
      return const StatusChip(type: StatusType.expiringSoon);
    } else {
      return const StatusChip(type: StatusType.active);
    }
  }

  /// 完了確認ダイアログを表示
  Future<void> _confirmCompletePlan(DilutionPlan plan) async {
    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      title: '割水計画の完了',
      message: 'タンク ${plan.result.tankNumber} の割水計画を完了としてマークしますか？',
      confirmText: '完了',
      cancelText: 'キャンセル',
    );
    
    if (confirm) {
      try {
        await _planManager.markPlanAsCompleted(plan.id);
        await _loadPlans();
        
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            '割水計画を完了としてマークしました',
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            'エラー: $e',
          );
        }
      }
    }
  }
}