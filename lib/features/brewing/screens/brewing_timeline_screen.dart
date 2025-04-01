import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../controllers/brewing_timeline_controller.dart';
import '../widgets/timeline_item_widget.dart';
import 'brewing_record_screen.dart';

/// 記帳サポートのタイムライン表示画面
class BrewingTimelineScreen extends StatefulWidget {
  /// 瓶詰め情報ID
  final String bottlingInfoId;

  /// コンストラクタ
  const BrewingTimelineScreen({
    Key? key,
    required this.bottlingInfoId,
  }) : super(key: key);

  @override
  State<BrewingTimelineScreen> createState() => _BrewingTimelineScreenState();
}

class _BrewingTimelineScreenState extends State<BrewingTimelineScreen> {
  /// Scaffoldキー (ドロワー表示用)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  /// コントローラー
  late BrewingTimelineController _controller;

  @override
void initState() {
  super.initState();
  
  // コントローラーの初期化（依存性注入を使用）
  _controller = BrewingTimelineController(
    recordService: Provider.of<BrewingRecordService>(context, listen: false),
  );
  
  // データの読み込み
  _controller.initialize(widget.bottlingInfoId);
}

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<BrewingTimelineController>(
        builder: (context, controller, child) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(controller.bottlingInfo != null 
                ? '記帳タイムライン - ${controller.bottlingInfo!.sakeName}' 
                : '記帳タイムライン'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.loadTimelineData,
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
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.errorMessage != null
                    ? _buildErrorView(controller.errorMessage!)
                    : controller.timelineData == null
                        ? const Center(child: Text('データがありません'))
                        : _buildTimelineView(controller),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _navigateToRecordEdit(context),
              tooltip: '記帳を編集',
              child: const Icon(Icons.edit),
            ),
          );
        },
      ),
    );
  }

  /// エラー表示を構築
  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 72.0,
            color: Colors.red,
          ),
          const SizedBox(height: 16.0),
          Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () => _controller.loadTimelineData(),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  /// タイムラインビューを構築
  Widget _buildTimelineView(BrewingTimelineController controller) {
    final timelineData = controller.timelineData!;
    final record = timelineData.record;
    final bottlingInfo = timelineData.bottlingInfo;
    final shortages = timelineData.shortages;
    
    // タイムラインの項目リスト
    final List<Widget> timelineItems = [];
    
    // 1. 瓶詰め情報
    timelineItems.add(
      TimelineItemWidget(
        type: TimelineItemType.bottling,
        title: '瓶詰め（${Formatters.dateFormat(bottlingInfo.createdAt)}）',
        contentLines: [
          'アルコール度数：${record.bottlingUpdate?.previousAlcoholPercentage.toStringAsFixed(1)}% → ${bottlingInfo.alcoholPercentage.toStringAsFixed(1)}%',
          '総量：${bottlingInfo.totalVolumeWithRemaining.toStringAsFixed(1)}L（${_formatBottleDetails(bottlingInfo)}）',
          '純アルコール量：${bottlingInfo.pureAlcoholAmount.toStringAsFixed(2)}L',
        ],
        onTap: () => _showBottlingDetails(context, bottlingInfo),
      ),
    );
    
    // 2. 瓶詰め欠減
    if (shortages.isNotEmpty) {
      final bottlingShortage = shortages.first; // 瓶詰め欠減は最初に計算される
      timelineItems.add(
        TimelineItemWidget(
          type: TimelineItemType.shortage,
          title: '瓶詰め欠減',
          contentLines: [
            '欠減：${bottlingShortage.amount.toStringAsFixed(1)}L（${bottlingShortage.startDescription}: ${bottlingShortage.startVolume.toStringAsFixed(1)}L → ${bottlingShortage.endDescription}: ${bottlingShortage.endVolume.toStringAsFixed(1)}L）[${bottlingShortage.percentage.toStringAsFixed(1)}%]',
          ],
          isCompact: true,
        ),
      );
    }
    
    // 3. 割水情報
    if (record.dilutionStage != null) {
      final dilution = record.dilutionStage!;
      timelineItems.add(
        TimelineItemWidget(
          type: TimelineItemType.dilution,
          title: '割水',
          contentLines: [
            'タンク: ${dilution.tankNumber}（検尺値: ${_formatDipstickChanges(dilution)}）',
            '数量: ${dilution.initialVolume.toStringAsFixed(1)}L → ${dilution.finalVolume.toStringAsFixed(1)}L（割水量: ${dilution.dilutionWaterAmount.toStringAsFixed(1)}L）',
            'アルコール度数: ${dilution.initialAlcoholPercentage.toStringAsFixed(1)}% → ${dilution.finalAlcoholPercentage.toStringAsFixed(1)}%（純アル量: ${(dilution.initialVolume * dilution.initialAlcoholPercentage / 100).toStringAsFixed(2)}L）',
          ],
          onTap: () => _showDilutionDetails(context, dilution),
        ),
      );
      
      
      // 4. 蔵出し情報
      timelineItems.add(
        TimelineItemWidget(
          type: TimelineItemType.extraction,
          title: '蔵出し',
          contentLines: [
            'タンク: ${dilution.tankNumber}（検尺値: ${dilution.initialDipstick.toStringAsFixed(0)}mm）',
            '蔵出し量: ${dilution.initialVolume.toStringAsFixed(1)}L',
            'アルコール度数: ${dilution.initialAlcoholPercentage.toStringAsFixed(1)}%（純アル量: ${(dilution.initialVolume * dilution.initialAlcoholPercentage / 100).toStringAsFixed(2)}L）',
          ],
        ),
      );

      // 蔵出し欠減（2番目の欠減）
      if (shortages.length > 1) {
        final extractionShortage = shortages[1];
        timelineItems.add(
          TimelineItemWidget(
            type: TimelineItemType.shortage,
            title: '蔵出し欠減',
            contentLines: [
              '欠減：${extractionShortage.amount.toStringAsFixed(1)}L（${extractionShortage.startDescription}: ${extractionShortage.startVolume.toStringAsFixed(1)}L → ${extractionShortage.endDescription}: ${extractionShortage.endVolume.toStringAsFixed(1)}L）[${extractionShortage.percentage.toStringAsFixed(1)}%]',
            ],
            isCompact: true,
          ),
        );
      }
    }
    
    // 5. タンク移動情報
    if (record.movementStages.isNotEmpty) {
      // 各移動ステージと欠減
      int shortageIndex = shortages.length > 2 ? 2 : 0; // 欠減インデックス
      
      for (int i = 0; i < record.movementStages.length; i++) {
        final movement = record.movementStages[i];
        
        // 移動欠減があれば表示
        if (i > 0 && shortageIndex < shortages.length) {
          final movementShortage = shortages[shortageIndex++];
          timelineItems.add(
            TimelineItemWidget(
              type: TimelineItemType.shortage,
              title: '${movement.processName ?? "移動"}欠減',
              contentLines: [
                '欠減：${movementShortage.amount.toStringAsFixed(1)}L（${movementShortage.startDescription}: ${movementShortage.startVolume.toStringAsFixed(1)}L → ${movementShortage.endDescription}: ${movementShortage.endVolume.toStringAsFixed(1)}L）[${movementShortage.percentage.toStringAsFixed(1)}%]',
              ],
              isCompact: true,
            ),
          );
        }
        
        // タン ク移動情報
        // タンク移動情報
timelineItems.add(
  TimelineItemWidget(
    type: TimelineItemType.movement,
    title: '${movement.processName ?? "タンク移動"} #${i + 1}',
    contentLines: [
      '移動元: ${movement.sourceTankNumber}',
      ' >>移動前: ${movement.sourceDipstick.toStringAsFixed(0)}mm / ${movement.sourceInitialVolume.toStringAsFixed(1)}L',
      ' >>移動量: ${movement.movementVolume.toStringAsFixed(1)}L',
      ' >>移動後: ${movement.sourceRemainingDipstick.toStringAsFixed(0)}mm / ${movement.sourceRemainingVolume.toStringAsFixed(1)}L(残量)',
      '移動先: ${movement.destinationTankNumber}（検尺値: ${movement.destinationDipstick.toStringAsFixed(0)}mm）',
    ],
    isLast: i == record.movementStages.length - 1 && (i + 1 == record.movementStages.length),
    onTap: () => _showMovementDetails(context, movement),
  ),
);
        
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        children: timelineItems,
      ),
    );
  }

  /// 瓶詰め詳細を表示
  void _showBottlingDetails(BuildContext context, dynamic bottlingInfo) {
    // 瓶詰め詳細表示（既存の機能を活用）
    // 実際の実装に合わせて調整
  }

  /// 割水詳細を表示
  void _showDilutionDetails(BuildContext context, dynamic dilution) {
    // 割水詳細表示
    // 実際の実装に合わせて調整
  }

  /// タンク移動詳細を表示
  void _showMovementDetails(BuildContext context, dynamic movement) {
    // タンク移動詳細表示
    // 実際の実装に合わせて調整
  }

  /// 瓶詰め情報の詳細をフォーマット
  String _formatBottleDetails(dynamic bottlingInfo) {
    final StringBuffer buffer = StringBuffer();
    
    // 瓶種ごとの情報を追加
    for (var i = 0; i < bottlingInfo.bottleEntries.length; i++) {
      final entry = bottlingInfo.bottleEntries[i];
      buffer.write('${entry.bottleType.capacity}ml×${entry.totalBottles}本');
      
      if (i < bottlingInfo.bottleEntries.length - 1) {
        buffer.write('、');
      }
    }
    
    // 詰残し情報
    if (bottlingInfo.remainingAmount > 0) {
      buffer.write('、詰残1.8L×${bottlingInfo.remainingAmount.toStringAsFixed(1)}本');
    }
    
    return buffer.toString();
  }

  /// 検尺値の変化をフォーマット
  String _formatDipstickChanges(dynamic dilution) {
    // 検尺値の変化表示方法に応じてフォーマット
    // 現在のシステムでは蔵出し→割水の検尺値変化が登録されていないので、
    // 初期値のみ表示
    return '${dilution.initialDipstick.toStringAsFixed(0)}mm';
  }

  /// 記帳編集画面に遷移
  void _navigateToRecordEdit(BuildContext context) async {
    if (_controller.bottlingInfo == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        '瓶詰め情報が読み込まれていません',
      );
      return;
    }

    // 記帳サポート画面へ遷移
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BrewingRecordScreen(
          bottlingInfo: _controller.bottlingInfo!,
        ),
      ),
    );
    
    if (result == true) {
      // 保存されたらデータを再読み込み
      _controller.loadTimelineData();
    }
  }
}