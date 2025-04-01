import 'package:flutter/material.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../controllers/bottling_manager.dart';
import '../models/bottling_info.dart';
import 'bottling_screen.dart';
import '../../brewing/screens/brewing_record_screen.dart';
import '../../../features/brewing/screens/brewing_timeline_screen.dart'; 
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart'; // タイムライン画面をインポート

/// 瓶詰め一覧画面
class BottlingListScreen extends StatefulWidget {
  /// コンストラクタ
  const BottlingListScreen({Key? key}) : super(key: key);

  @override
  State<BottlingListScreen> createState() => _BottlingListScreenState();
}

class _BottlingListScreenState extends State<BottlingListScreen> {
  /// Scaffoldキー (ドロワー表示用)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 瓶詰め情報マネージャー
late BottlingManager _bottlingManager;
  
  /// 瓶詰め情報リスト
  List<BottlingInfo> _bottlingInfos = [];
  
  /// 読み込み中フラグ
  bool _isLoading = true;

  @override
void initState() {
  super.initState();
  _bottlingManager = BottlingManager(
    Provider.of<StorageService>(context, listen: false)
  );
  _loadBottlingInfos();
}

  /// 瓶詰め情報を読み込む
  Future<void> _loadBottlingInfos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bottlingInfos = await _bottlingManager.getAllBottlingInfos();
      
      setState(() {
        _bottlingInfos = bottlingInfos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          '瓶詰め情報の読み込みに失敗しました: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('瓶詰め一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBottlingInfos,
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
      ),
      endDrawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bottlingInfos.isEmpty
              ? _buildEmptyState()
              : _buildBottlingList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToBottlingScreen(context),
        tooltip: '新規瓶詰め',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 空の状態を構築
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.liquor,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 16.0),
          Text(
            '瓶詰め情報はありません',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton.icon(
            onPressed: () => _navigateToBottlingScreen(context),
            icon: const Icon(Icons.add),
            label: const Text('新規瓶詰め'),
          ),
        ],
      ),
    );
  }

  /// 瓶詰めリストを構築
  Widget _buildBottlingList() {
    return RefreshIndicator(
      onRefresh: _loadBottlingInfos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _bottlingInfos.length,
        itemBuilder: (context, index) {
          final bottlingInfo = _bottlingInfos[index];
          return _buildBottlingItem(bottlingInfo);
        },
      ),
    );
  }

  /// 瓶詰めアイテムを構築
  Widget _buildBottlingItem(BottlingInfo bottlingInfo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _showBottlingDetails(context, bottlingInfo),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bottlingInfo.sakeName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    Formatters.dateFormat(bottlingInfo.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.percent, size: 16),
                  const SizedBox(width: 4.0),
                  Text(
                    'アルコール度数: ${bottlingInfo.alcoholPercentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  const Icon(Icons.liquor, size: 16),
                  const SizedBox(width: 4.0),
                  Text(
                    '総本数: ${bottlingInfo.totalBottles}本',
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
                    '総容量: ${bottlingInfo.totalVolume.toStringAsFixed(1)}L',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (bottlingInfo.remainingAmount > 0) ...[
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    const Icon(Icons.more_horiz, size: 16),
                    const SizedBox(width: 4.0),
                    Text(
                      '詰残: ${bottlingInfo.remainingAmount}本分 (${(bottlingInfo.remainingAmount * 1.8).toStringAsFixed(1)}L)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editBottlingInfo(context, bottlingInfo),
                    icon: const Icon(Icons.edit),
                    label: const Text('編集'),
                  ),
                  const SizedBox(width: 8.0),
                  TextButton.icon(
                    onPressed: () => _confirmDeleteBottlingInfo(context, bottlingInfo),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('削除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// 瓶詰め詳細を表示
  // lib/features/bottling/screens/bottling_list_screen.dart 内の _showBottlingDetails メソッドを以下のように修正

void _showBottlingDetails(BuildContext context, BottlingInfo bottlingInfo) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7, // より広く表示
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      margin: const EdgeInsets.only(bottom: 16.0),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '瓶詰め詳細（記帳用）',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // 基本情報ヘッダー
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '酒名: ${bottlingInfo.sakeName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                Formatters.dateFormat(bottlingInfo.date),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'アルコール度数: ${bottlingInfo.alcoholPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (bottlingInfo.temperature != null) ...[
                            const SizedBox(height: 4.0),
                            Text(
                              '品温: ${bottlingInfo.temperature!.toStringAsFixed(1)}℃',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16.0),
                  // 瓶種情報テーブル（記帳向け最適化）
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '瓶詰め数量明細',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12.0),
                          
                          // テーブルヘッダー
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                              color: Colors.grey[100],
                            ),
                            child: Row(
                              children: const [
                                Expanded(flex: 3, child: Text('瓶種', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text('ケース', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                Expanded(flex: 1, child: Text('バラ', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                Expanded(flex: 1, child: Text('本数', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                Expanded(flex: 2, child: Text('容量(L)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                Expanded(flex: 2, child: Text('純アル(L)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          
                          // 瓶種ごとの行
                          ...bottlingInfo.bottleEntries.map((entry) {
                            final pureAlcohol = entry.totalVolume * bottlingInfo.alcoholPercentage / 100;
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3, 
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.bottleType.name),
                                        Text('${entry.bottleType.capacity}ml', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 1, child: Text('${entry.cases}', textAlign: TextAlign.center)),
                                  Expanded(flex: 1, child: Text('${entry.bottles}', textAlign: TextAlign.center)),
                                  Expanded(flex: 1, child: Text('${entry.totalBottles}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text(entry.totalVolume.toStringAsFixed(1), textAlign: TextAlign.center)),
                                  Expanded(flex: 2, child: Text(pureAlcohol.toStringAsFixed(2), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
                                ],
                              ),
                            );
                          }).toList(),
                          
                          // 詰め残行
                          if (bottlingInfo.remainingAmount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                color: Colors.grey[50],
                              ),
                              child: Row(
                                children: [
                                  const Expanded(flex: 3, child: Text('詰め残', style: TextStyle(fontStyle: FontStyle.italic))),
                                  const Expanded(flex: 1, child: Text('')),
                                  const Expanded(flex: 1, child: Text('')),
                                  Expanded(flex: 1, child: Text('${bottlingInfo.remainingAmount.toStringAsFixed(1)}', textAlign: TextAlign.center)),
                                  Expanded(flex: 2, child: Text('${(bottlingInfo.remainingAmount * 1.8).toStringAsFixed(1)}', textAlign: TextAlign.center)),
                                  Expanded(
                                    flex: 2, 
                                    child: Text(
                                      '${((bottlingInfo.remainingAmount * 1.8) * bottlingInfo.alcoholPercentage / 100).toStringAsFixed(2)}', 
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // 合計行
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            ),
                            child: Row(
                              children: [
                                const Expanded(flex: 3, child: Text('合計', style: TextStyle(fontWeight: FontWeight.bold))),
                                const Expanded(flex: 1, child: Text('')),
                                const Expanded(flex: 1, child: Text('')),
                                Expanded(flex: 1, child: Text('${bottlingInfo.totalBottles}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(
                                  flex: 2, 
                                  child: Text(
                                    bottlingInfo.totalVolumeWithRemaining.toStringAsFixed(1), 
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  flex: 2, 
                                  child: Text(
                                    bottlingInfo.pureAlcoholAmount.toStringAsFixed(2), 
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),
                  // アクションボタン
                  Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        _editBottlingInfo(context, bottlingInfo);
      },
      icon: const Icon(Icons.edit),
      label: const Text('編集'),
    ),
    const SizedBox(width: 12),
    ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BrewingRecordScreen(bottlingInfo: bottlingInfo),
          ),
        ).then((_) => _loadBottlingInfos());
      },
      icon: const Icon(Icons.book),
      label: const Text('記帳サポート'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    ),
    ElevatedButton.icon(
  onPressed: () {
    Navigator.of(context).pop();
    _navigateToTimeline(context, bottlingInfo);
  },
  icon: const Icon(Icons.timeline),
  label: const Text('タイムライン表示'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
    foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
  ),
),
  ],
),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}



  /// 詳細アイテムを構築
  Widget _buildDetailItem(
    String label, 
    String value, {
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  /// テーブルヘッダーを構築
  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// テーブルセルを構築
  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 瓶詰め画面に遷移
  Future<void> _navigateToBottlingScreen(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const BottlingScreen(),
      ),
    );
    
    if (result == true) {
      // 保存されたら瓶詰め情報を再読み込み
      await _loadBottlingInfos();
    }
  }

  /// 瓶詰め情報を編集
  Future<void> _editBottlingInfo(
    BuildContext context, 
    BottlingInfo bottlingInfo,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BottlingScreen(bottlingInfo: bottlingInfo),
      ),
    );
    
    if (result == true) {
      // 保存されたら瓶詰め情報を再読み込み
      await _loadBottlingInfos();
    }
  }

  /// 瓶詰め情報の削除確認
  Future<void> _confirmDeleteBottlingInfo(
    BuildContext context, 
    BottlingInfo bottlingInfo,
  ) async {
    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      title: '瓶詰め情報の削除',
      message: '${bottlingInfo.sakeName}の瓶詰め情報を削除しますか？\nこの操作は元に戻せません。',
      confirmText: '削除',
      cancelText: 'キャンセル',
    );
    
    if (confirm) {
      try {
        await _bottlingManager.deleteBottlingInfo(bottlingInfo.id);
        
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            '瓶詰め情報を削除しました',
          );
        }
        
        await _loadBottlingInfos();
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            '削除に失敗しました: $e',
          );
        }
      }
    }
  }
  void _navigateToTimeline(BuildContext context, BottlingInfo bottlingInfo) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => BrewingTimelineScreen(
        bottlingInfoId: bottlingInfo.id,
      ),
    ),
  );
}
}