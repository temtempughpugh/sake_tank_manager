import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/tank_selector.dart';
import '../../../shared/widgets/tank_volume_selector.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/models/measurement_data.dart';
import '../../bottling/models/bottling_info.dart';
import '../controllers/brewing_record_controller.dart';
import 'tank_movement_screen.dart';
import '../models/brewing_record.dart';
import '../controllers/brewing_record_service.dart';
import '../../../core/services/tank_data_service.dart';
import '../../../core/services/calculation_service.dart';

/// 記帳サポートメイン画面
class BrewingRecordScreen extends StatefulWidget {
  /// 瓶詰め情報
  final BottlingInfo bottlingInfo;
  
  /// 編集する記録 (オプション)
  final BrewingRecord? existingRecord;

  /// コンストラクタ
  const BrewingRecordScreen({
    Key? key,
    required this.bottlingInfo,
    this.existingRecord,
  }) : super(key: key);

  @override
  State<BrewingRecordScreen> createState() => _BrewingRecordScreenState();
}

class _BrewingRecordScreenState extends State<BrewingRecordScreen> {
  /// Scaffoldキー (ドロワー表示用)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  /// コントローラー
  late BrewingRecordController _controller;
  
  /// 初期アルコール度数コントローラー
  final TextEditingController _initialAlcoholController = TextEditingController();
  
  /// ページコントローラー
  final PageController _pageController = PageController();
  
  /// 現在のページインデックス
  int _currentPageIndex = 0;

@override
void initState() {
  super.initState();
  
  // コントローラーの初期化（依存性注入を使用）
  _controller = BrewingRecordController(
    recordService: Provider.of<BrewingRecordService>(context, listen: false),
    tankDataService: Provider.of<TankDataService>(context, listen: false),
    calculationService: Provider.of<CalculationService>(context, listen: false),
  );
  
  // データの読み込み
  _controller.initialize().then((_) {
    _controller.loadBottlingInfo(widget.bottlingInfo.id).then((_) {
      // 既存の記録があれば編集モードにする
      if (widget.existingRecord != null) {
        _controller.setEditMode(widget.existingRecord!);
      }
    });
  });
}

  @override
  void dispose() {
    _initialAlcoholController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<BrewingRecordController>(
        builder: (context, controller, child) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(_currentPageIndex == 0 
                  ? '記帳補助 - 瓶詰め情報' 
                  : '蔵出し/割水情報'),
              actions: [
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
                : controller.bottlingInfo == null
                    ? const Center(child: Text('瓶詰め情報を読み込めませんでした'))
                    : PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentPageIndex = index;
                          });
                        },
                        children: [
                          _buildBottlingInfoPage(controller),
                          _buildDilutionPage(controller),
                        ],
                      ),
          );
        },
      ),
    );
  }

  /// 瓶詰め情報ページを構築
  Widget _buildBottlingInfoPage(BrewingRecordController controller) {
    final bottlingInfo = controller.bottlingInfo!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 瓶詰め情報サマリー
          SectionCard(
            title: '瓶詰め情報',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bottlingInfo.sakeName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '日付: ${Formatters.dateFormat(bottlingInfo.date)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4.0),
                Text(
                  'アルコール度数: ${bottlingInfo.alcoholPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4.0),
                Text(
                  '純アルコール量: ${bottlingInfo.pureAlcoholAmount.toStringAsFixed(1)}L',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // 瓶詰め内訳
          SectionCard(
            title: '瓶詰め内訳',
            icon: Icons.list,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...bottlingInfo.bottleEntries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '${entry.bottleType.name}(${entry.bottleType.capacity}ml): ${entry.totalBottles}本 (${entry.totalVolume.toStringAsFixed(1)}L)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
                
                if (bottlingInfo.remainingAmount > 0) ...[
                  const Divider(),
                  Text(
                    '詰め残し: ${bottlingInfo.remainingAmount.toStringAsFixed(1)}本分 (${(bottlingInfo.remainingAmount * 1.8).toStringAsFixed(1)}L)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                
                const Divider(),
                
                Text(
                  '総容量: ${controller.bottlingTotalVolume.toStringAsFixed(1)}L',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // タンク選択
          TankSelector(
            selectedTankNumber: controller.dilutionTankNumber,
            onTankSelected: (tankNumber) {
              controller.setDilutionTank(tankNumber);
            },
          ),
          
          const SizedBox(height: 16.0),
          
          // 割水後数量選択
          // 割水後数量選択
          if (controller.dilutionTankNumber != null)
  TankVolumeSelector(
    tankNumber: controller.dilutionTankNumber!,
    title: '割水後数量選択',
    useDipstickAsReference: false,
    selectedVolume: controller.finalMeasurement?.volume,
    onMeasurementSelected: (measurement) {
      controller.setFinalMeasurement(measurement);
    },
    visibleItemCount: 3, // 3つに変更
    referenceValue: controller.bottlingTotalVolume, // 瓶詰め総量を基準に
  ),
          
          // 欠減計算
          if (controller.finalMeasurement != null)
            SectionCard(
              title: '欠減計算(瓶詰め)',
              icon: Icons.calculate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '瓶詰め総量: ${controller.bottlingTotalVolume.toStringAsFixed(1)}L',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '欠減量: ${controller.bottlingShortage.toStringAsFixed(1)}L (${controller.bottlingShortagePercentage.toStringAsFixed(2)}%)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: controller.bottlingShortage < 0 ? Colors.red : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16.0),
          
          // 次へボタン
          if (controller.finalMeasurement != null)
            ElevatedButton.icon(
              onPressed: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('次へ: 蔵出し/割水情報'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
        ],
      ),
    );
  }

  /// 蔵出し/割水情報ページを構築
  Widget _buildDilutionPage(BrewingRecordController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 蔵出し数量選択
          // 前画面の要約表示
if (controller.bottlingInfo != null && controller.finalMeasurement != null) ...[
  SectionCard(
    title: '瓶詰め情報・割水後数量（要約）',
    icon: Icons.summarize,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${controller.bottlingInfo!.sakeName} (${Formatters.dateFormat(controller.bottlingInfo!.date)})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4.0),
        Text(
          '瓶詰め総量: ${controller.bottlingTotalVolume.toStringAsFixed(1)}L',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '選択割水タンク: ${controller.dilutionTankNumber}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '割水後数量: ${controller.finalMeasurement!.volume.toStringAsFixed(1)}L (${controller.finalMeasurement!.dipstick.toStringAsFixed(0)}mm)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (controller.bottlingShortage != 0) Text(
          '欠減量: ${controller.bottlingShortage.toStringAsFixed(1)}L (${controller.bottlingShortagePercentage.toStringAsFixed(2)}%)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: controller.bottlingShortage < 0 ? Colors.red : null,
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 16.0),
],
if (controller.dilutionTankNumber != null)
  TankVolumeSelector(
    tankNumber: controller.dilutionTankNumber!,
    title: '蔵出し数量選択',
    useDipstickAsReference: false,
    selectedVolume: controller.initialMeasurement?.volume,
    onMeasurementSelected: (measurement) {
      controller.setInitialMeasurement(measurement);
    },
    visibleItemCount: 3, // 3つに変更
    referenceValue: controller.finalMeasurement?.volume, // 割水後数量に近い順
  ),
          
          const SizedBox(height: 16.0),
          
          // アルコール度数
          SectionCard(
            title: 'アルコール度数',
            icon: Icons.percent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 割水前アルコール度数
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: '割水前',
                    hintText: '19.2',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: controller.initialAlcoholPercentage > 0
                      ? controller.initialAlcoholPercentage.toString()
                      : '',
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final percentage = double.tryParse(value);
                      if (percentage != null) {
                        controller.setInitialAlcoholPercentage(percentage);
                      }
                    }
                  },
                ),
                
                const SizedBox(height: 16.0),
                
                // 割水後アルコール度数
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: '割水後',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    suffixText: '%',
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  child: Text(
                    controller.finalAlcoholPercentage > 0
                        ? controller.finalAlcoholPercentage.toStringAsFixed(1)
                        : controller.bottlingInfo?.alcoholPercentage.toStringAsFixed(1) ?? '',
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '(自動計算)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16.0),
          
          // 計算結果
          if (controller.isCalculated)
            SectionCard(
              title: '計算結果',
              icon: Icons.check_circle_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '割水量: ${controller.dilutionWaterAmount.toStringAsFixed(1)} L',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '割水後数量: ${controller.finalMeasurement!.volume.toStringAsFixed(1)}L (${controller.finalMeasurement!.dipstick.toInt()}mm)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16.0),
          
          // 警告表示
          if (controller.isCalculated && 
              controller.bottlingInfo!.alcoholPercentage != controller.finalAlcoholPercentage)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '※蔵出し数量変更により割水後アルコール度数が変動します。',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  Text(
                    '瓶詰め情報も更新されます。',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16.0),
          // タンク移動リスト表示
if (controller.movementStages.isNotEmpty) ...[
  const SizedBox(height: 16.0),
  SectionCard(
    title: 'タンク移動リスト',
    icon: Icons.swap_horiz,
    child: Column(
      children: [
        ...controller.movementStages.asMap().entries.map((entry) {
          final index = entry.key;
          final stage = entry.value;
          return ListTile(
            title: Text('${stage.processName ?? "タンク移動"} ${index + 1}'),
            subtitle: Text('${stage.sourceTankNumber} → ${stage.destinationTankNumber}  (${stage.movementVolume.toStringAsFixed(1)}L)'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                controller.removeMovementStage(index);
              },
            ),
          );
        }).toList(),
      ],
    ),
  ),
],
          // 操作ボタン
          // 操作ボタンの条件分岐を修正
if (controller.isCalculated) ...[
  if (!controller.isEditMode)
    ElevatedButton.icon(
      onPressed: _saveRecord,
      icon: const Icon(Icons.save),
      label: const Text('変更を記録・瓶詰め情報更新'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: Colors.orange,
      ),
    )
  else
    ElevatedButton.icon(
      onPressed: _updateRecord,
      icon: const Icon(Icons.update),
      label: const Text('記帳データを更新'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: Colors.orange,
      ),
    ),
  
  const SizedBox(height: 12.0),
  
  ElevatedButton.icon(
    onPressed: _addTankMovement,
    icon: const Icon(Icons.swap_horiz),
    label: const Text('タンク移動を追加'),
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
    ),
  ),
],
          
          const SizedBox(height: 12.0),
          
          // 戻るボタン
          TextButton.icon(
            onPressed: () {
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('戻る'),
          ),
          
          // エラー表示
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.red[50],
              child: Text(
                controller.errorMessage!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// タンク移動を追加
  /// タンク移動を追加
// lib/features/brewing/screens/brewing_record_screen.dart の _addTankMovement() メソッド

void _addTankMovement() async {
  if (!_controller.isCalculated || _controller.initialMeasurement == null) {
    ErrorHandler.showErrorSnackBar(
      context,
      '蔵出し情報を先に計算してください',
    );
    return;
  }

  // 移動元タンクと数量を設定
  String? sourceNumber;      
  double sourceVolume = 0.0;  // 初期値を設定
  double sourceDipstick = 0.0; // 初期値を設定
  String destinationNumber;  
  double? previousSourceInitialVolume; // 前の移動元タンク総量

  if (_controller.movementStages.isNotEmpty) {
    // 既存の移動がある場合は最後の移動元を今回の移動先に設定
    final lastMovement = _controller.movementStages.last;
    destinationNumber = lastMovement.sourceTankNumber;
    
    // 前回の移動元タンクの総量を今回の参照値として渡す
    previousSourceInitialVolume = lastMovement.sourceInitialVolume;
  } else {
    // 最初の移動では割水タンクが移動先
    destinationNumber = _controller.dilutionTankNumber!;
    sourceVolume = _controller.initialMeasurement!.volume;
    sourceDipstick = _controller.initialMeasurement!.dipstick;
    
    // 最初の移動ではnullを渡す（蔵出し数量を使用するため）
    previousSourceInitialVolume = null;
  }

  // タンク移動画面へ遷移
  final result = await Navigator.of(context).push<MovementStageData>(
    MaterialPageRoute(
      builder: (context) => TankMovementScreen(
        sourceTankNumber: sourceNumber,
        destinationTankNumber: destinationNumber,
        initialVolume: sourceVolume,
        initialDipstick: sourceDipstick,
        previousSourceInitialVolume: previousSourceInitialVolume, // 正しい参照値を渡す
      ),
    ),
  );
  
  if (result != null) {
    // タンク移動を追加
    _controller.addMovementStage(result);
    
    if (mounted) {
      ErrorHandler.showSuccessSnackBar(
        context,
        'タンク移動情報を追加しました',
      );
    }
  }
}

  /// 記帳データを保存
  void _saveRecord() async {
    try {
      await _controller.saveBrewingRecord();
      
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          '記帳データを保存し、瓶詰め情報を更新しました',
        );
        
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          '保存に失敗しました: $e',
        );
      }
    }
  }
/// 記帳データを更新
/// 記帳データを更新
void _updateRecord() async {
  try {
    await _controller.updateBrewingRecord();
    
    if (mounted) {
      ErrorHandler.showSuccessSnackBar(
        context,
        '記帳データを更新しました',
      );
      
      Navigator.of(context).pop(true);
    }
  } catch (e) {
    if (mounted) {
      ErrorHandler.showErrorSnackBar(
        context,
        '更新に失敗しました: $e',
      );
    }
  }
}



}