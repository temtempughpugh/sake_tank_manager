import 'package:flutter/material.dart';
import '../features/dilution/controllers/dilution_plan_manager.dart';
import '../features/dilution/models/dilution_plan.dart';
import '../core/utils/formatters.dart';
import '../shared/widgets/status_chip.dart';
import '../shared/widgets/section_card.dart';
import '../shared/widgets/app_drawer.dart';
import '../features/brewing/screens/brewing_record_list_screen.dart';
import 'package:provider/provider.dart';
import '../core/services/storage_service.dart';

/// ホーム画面
class HomeScreen extends StatefulWidget {
  /// コンストラクタ
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

/// ホーム画面の状態クラス
class HomeScreenState extends State<HomeScreen> {
  /// Scaffoldキー (ドロワー表示用)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  /// 割水計画マネージャー
  late DilutionPlanManager _planManager;

  /// 進行中の割水計画リスト
  List<DilutionPlan> _activeDilutionPlans = [];
  
  /// 読み込み中フラグ
  bool _isLoading = true;

@override
void initState() {
  super.initState();
  
  _planManager = DilutionPlanManager(
    Provider.of<StorageService>(context, listen: false)
  );
  
  _loadData();
}

  /// データの読み込み
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 割水計画データの読み込み
      await _planManager.initialize();
      final activePlans = await _planManager.getActivePlans();

      setState(() {
        _activeDilutionPlans = activePlans;
        _isLoading = false;
      });
      
      // デバッグ出力
      print('読み込まれた割水計画数: ${_activeDilutionPlans.length}');
    } catch (e) {
      print('データの読み込みエラー: $e');
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
        title: const Text('日本酒タンク管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '更新',
          ),
          // ドロワーを開くボタンを明示的に表示
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            tooltip: 'メニュー',
          ),
        ],
      ),
      // 共通のドロワーウィジェットを使用
      endDrawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusSummary(context),
                    const SizedBox(height: 16.0),
                    _buildDilutionSection(context),
                    const SizedBox(height: 16.0),
                    _buildFireProcessingSection(context),
                    const SizedBox(height: 16.0),
                    _buildFiltrationSection(context),
                    const SizedBox(height: 16.0),
                    _buildBottlingSection(context),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewProcessDialog(context);
        },
        tooltip: '新規作業',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// ステータスサマリーを構築
  Widget _buildStatusSummary(BuildContext context) {
    // 全作業数
    final int totalTasks = _activeDilutionPlans.length;
    
    // 期限切れの作業数
    final int expiredTasks = _activeDilutionPlans
        .where((plan) => plan.daysSinceCreation >= 7)
        .length;
    
    // まもなく期限の作業数
    final int expiringSoonTasks = _activeDilutionPlans
        .where((plan) => 
            plan.daysSinceCreation >= 5 && 
            plan.daysSinceCreation < 7)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '作業状況',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8.0),
            Text(
              '現在$totalTasks件の進行中作業があります',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (expiredTasks > 0 || expiringSoonTasks > 0) ...[
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                children: [
                  if (expiredTasks > 0)
                    Chip(
                      label: Text('期限超過: $expiredTasks件'),
                      backgroundColor: Colors.red[100],
                      labelStyle: TextStyle(color: Colors.red[800]),
                    ),
                  if (expiringSoonTasks > 0)
                    Chip(
                      label: Text('まもなく期限: $expiringSoonTasks件'),
                      backgroundColor: Colors.orange[100],
                      labelStyle: TextStyle(color: Colors.orange[800]),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 割水セクションを構築
  Widget _buildDilutionSection(BuildContext context) {
    print('割水計画セクション構築: ${_activeDilutionPlans.length}件');
    
    return SectionCard(
      title: '割水作業',
      icon: Icons.water_drop,
      actionText: '全て見る',
      action: IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () {
          Navigator.of(context).pushNamed('/dilution-plans');
        },
        tooltip: '割水計画一覧',
      ),
      child: _activeDilutionPlans.isEmpty
          ? _buildEmptyMessage('進行中の割水作業はありません')
          : Column(
              children: _activeDilutionPlans
                  .take(3) // 最大3件表示
                  .map((plan) => _buildDilutionPlanItem(context, plan))
                  .toList(),
            ),
    );
  }

  /// 火入れセクションを構築
  Widget _buildFireProcessingSection(BuildContext context) {
    // 将来的には実際のデータを表示
    return SectionCard(
      title: '火入れ作業',
      icon: Icons.local_fire_department,
      actionText: '全て見る',
      action: IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () {
          _showDevelopmentSnackBar(context);
        },
        tooltip: '火入れ一覧',
      ),
      child: _buildEmptyMessage('進行中の火入れ作業はありません'),
    );
  }

  /// ろ過セクションを構築
  Widget _buildFiltrationSection(BuildContext context) {
    // 将来的には実際のデータを表示
    return SectionCard(
      title: 'ろ過作業',
      icon: Icons.filter_alt,
      actionText: '全て見る',
      action: IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () {
          _showDevelopmentSnackBar(context);
        },
        tooltip: 'ろ過一覧',
      ),
      child: _buildEmptyMessage('進行中のろ過作業はありません'),
    );
  }

  /// 瓶詰めセクションを構築
  Widget _buildBottlingSection(BuildContext context) {
  // 将来的には実際のデータを表示
  return SectionCard(
    title: '瓶詰め作業',
    icon: Icons.liquor,
    actionText: '全て見る',
    action: IconButton(
      icon: const Icon(Icons.arrow_forward),
      onPressed: () {
        Navigator.of(context).pushNamed('/bottling-list');
      },
      tooltip: '瓶詰め一覧',
    ),
    child: _buildEmptyMessage('進行中の瓶詰め作業はありません'),
  );
}


  /// 空の状態メッセージを構築
  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  /// 割水計画アイテムを構築
  Widget _buildDilutionPlanItem(BuildContext context, DilutionPlan plan) {
    final result = plan.result;
    final expiringSoon = plan.daysSinceCreation >= 5 && plan.daysSinceCreation < 7;
    final expired = plan.daysSinceCreation >= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/dilution-plans');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'タンク ${result.tankNumber}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8.0),
                        StatusChip.fromDilutionPlan(plan),
                      ],
                    ),
                    if (result.sakeName != null && result.sakeName!.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        '酒名: ${result.sakeName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 4.0),
                    Text(
                      '追加水量: ${Formatters.volume(result.waterAmount)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '計画日: ${Formatters.dateFormat(plan.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _markPlanAsCompleted(context, plan),
                tooltip: '完了としてマーク',
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 開発中のSnackBarを表示
  void _showDevelopmentSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('この機能は現在開発中です'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 新規プロセスダイアログを表示
  void _showNewProcessDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('新規作業'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text('割水計算'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/dilution');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_fire_department),
            title: const Text('火入れ'),
            enabled: false,
            onTap: () {
              Navigator.of(context).pop();
              _showDevelopmentSnackBar(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.filter_alt),
            title: const Text('ろ過'),
            enabled: false,
            onTap: () {
              Navigator.of(context).pop();
              _showDevelopmentSnackBar(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.liquor),
            title: const Text('瓶詰め'),
            enabled: true,  // false から true に変更
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/bottling');  // 開発中スナックバーから実際のナビゲーションに変更
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('記帳サポート'),
            enabled: true,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/brewing-records');
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    ),
  );
}

  /// 計画を完了としてマークする
  Future<void> _markPlanAsCompleted(BuildContext context, DilutionPlan plan) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('確認'),
            content: Text('タンク ${plan.result.tankNumber} の割水計画を完了としてマークしますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('完了'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _planManager.markPlanAsCompleted(plan.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('割水計画を完了としてマークしました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラー: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}