import 'package:flutter/material.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/tank_selector.dart';
import '../../../shared/widgets/tank_volume_selector.dart';
import '../../../core/models/measurement_data.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/services/tank_data_service.dart';
import '../controllers/brewing_record_controller.dart';

/// タンク移動追加画面
class TankMovementScreen extends StatefulWidget {
  final String? sourceTankNumber;
  final String? destinationTankNumber;
  final double initialVolume; // 蔵出し数量
  final double initialDipstick; // 蔵出し検尺値
  final double? previousSourceInitialVolume; // 前のタンク総量（nullable）

  const TankMovementScreen({
    Key? key,
    this.sourceTankNumber,
    this.destinationTankNumber,
    required this.initialVolume,
    required this.initialDipstick,
    this.previousSourceInitialVolume, // 新規追加
  }) : super(key: key);

  @override
  State<TankMovementScreen> createState() => _TankMovementScreenState();
}

class _TankMovementScreenState extends State<TankMovementScreen> {
  /// タンクデータサービス
  final TankDataService _tankDataService = TankDataService();

  String? _sourceTankNumber;
  String? _destinationTankNumber; // 移動先タンク番号の状態変数を追加
  
  /// 移動数量の測定データ
  MeasurementData? _movementMeasurement;
  
  /// 残量の測定データ
  MeasurementData? _remainingMeasurement;
  
  /// 移動先検尺値 (新規追加)
  double _destinationDipstick = 0.0;
  
  /// プロセス名コントローラー
  final TextEditingController _processNameController = TextEditingController();
  
  /// 移動前タンク総量（移動量＋残量）
  double _sourceInitialVolume = 0.0;
  
  /// 欠減量（移動量と次工程数量の差）
  double _shortageMovement = 0.0;
  
  /// 欠減率
  double _shortageMovementPercentage = 0.0;
  
  /// 計算完了フラグ
  bool _isCalculated = false;
  
  /// タンク残量なしフラグ
  bool _isZeroRemaining = false;

  @override
  void initState() {
    super.initState();
    
    // 移動元タンク番号の初期化
    if (widget.sourceTankNumber != null) {
      _sourceTankNumber = widget.sourceTankNumber;
    }
    
    // 移動先タンク番号の初期化
    if (widget.destinationTankNumber != null && widget.destinationTankNumber!.isNotEmpty) {
      _destinationTankNumber = widget.destinationTankNumber;
      
      // 移動先の初期検尺値を設定
      _destinationDipstick = widget.initialDipstick;
    }
    
    // デフォルトプロセス名を設定
    _processNameController.text = '火入れ工程';
  }

  @override
  void dispose() {
    _processNameController.dispose();
    super.dispose();
  }

  /// 移動計算を実行
  void _calculateMovement() {
    if (_sourceTankNumber == null || _movementMeasurement == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        '移動元タンクと移動数量を選択してください',
      );
      return;
    }
    
    if (_destinationTankNumber == null || _destinationTankNumber!.isEmpty) {
      ErrorHandler.showErrorSnackBar(
        context,
        '移動先タンクを選択してください',
      );
      return;
    }

    // 欠減量の計算
    _shortageMovement = _movementMeasurement!.volume - widget.initialVolume;
    
    // 欠減率の計算（小数点以下2桁まで）
    _shortageMovementPercentage = (_shortageMovement / _movementMeasurement!.volume) * 100;
    
    // 移動前タンク総量の計算
    if (_remainingMeasurement != null) {
      _sourceInitialVolume = _movementMeasurement!.volume + _remainingMeasurement!.volume;
    } else {
      _sourceInitialVolume = _movementMeasurement!.volume;
    }
    
    setState(() {
      _isCalculated = true;
    });
  }

  /// 移動情報を作成して返す
  MovementStageData _createMovementStageData() {
    // 移動先検尺値を取得
    double destinationDipstick = _destinationDipstick;
    
    // 可能であれば移動先タンクから検尺値を計算
    if (_destinationTankNumber != null) {
      final tank = _tankDataService.getTank(_destinationTankNumber!);
      if (tank != null) {
        final result = tank.volumeToDipstick(_movementMeasurement!.volume);
        if (result != null) {
          destinationDipstick = result;
        }
      }
    }
    
    return MovementStageData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceTankNumber: _sourceTankNumber!,
      destinationTankNumber: _destinationTankNumber ?? '',
      movementVolume: _movementMeasurement!.volume,
      sourceDipstick: _movementMeasurement!.dipstick,
      destinationDipstick: destinationDipstick,
      sourceRemainingVolume: _remainingMeasurement?.volume ?? 0.0,
      sourceRemainingDipstick: _remainingMeasurement?.dipstick ?? 0.0,
      sourceInitialVolume: _sourceInitialVolume,
      shortageMovement: _shortageMovement,
      shortageMovementPercentage: _shortageMovementPercentage,
      processName: _processNameController.text.isNotEmpty 
          ? _processNameController.text 
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('タンク移動情報'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
  title: '移動元情報',
  icon: Icons.info_outline,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.previousSourceInitialVolume != null) ...[
        Text(
          '前タンク総量: ${widget.previousSourceInitialVolume!.toStringAsFixed(1)}L',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ] else if (widget.sourceTankNumber == null) ...[
        Text(
          '工程元容量: ${widget.initialVolume.toStringAsFixed(1)}L',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4.0),
        Text(
          '工程元検尺値: ${widget.initialDipstick.toStringAsFixed(0)}mm',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ] else ...[
        Text(
          '前タンク総量: データなし',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ],
  ),
),
            
            const SizedBox(height: 16.0),
            
            // 移動情報フォーム
            SectionCard(
              title: _processNameController.text.isEmpty 
                  ? '移動 #1' 
                  : '移動 #1 (${_processNameController.text})',
              icon: Icons.swap_horiz,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // プロセス名
                  TextFormField(
                    controller: _processNameController,
                    decoration: const InputDecoration(
                      labelText: '工程名',
                      hintText: '火入れ工程、ろ過など',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                  
                  const SizedBox(height: 16.0),
                  
                  // 移動元タンク選択
                  const Text('移動元タンク:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TankSelector(
                    selectedTankNumber: _sourceTankNumber,
                    onTankSelected: (tankNumber) {
                      setState(() {
                        _sourceTankNumber = tankNumber;
                        _movementMeasurement = null;
                        _remainingMeasurement = null;
                        _isCalculated = false;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16.0),
                  
                  // 移動先タンク選択 (変更部分)
                  const Text('移動先タンク:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TankSelector(
                    selectedTankNumber: _destinationTankNumber,
                    onTankSelected: (tankNumber) {
                      setState(() {
                        _destinationTankNumber = tankNumber;
                        _isCalculated = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16.0),
            
            // 移動数量選択
            if (_sourceTankNumber != null)
              TankVolumeSelector(
                tankNumber: _sourceTankNumber!,
                title: '移動数量選択',
                useDipstickAsReference: false,
                selectedVolume: _movementMeasurement?.volume,
                onMeasurementSelected: (measurement) {
                  setState(() {
                    _movementMeasurement = measurement;
                    _isCalculated = false;
                  });
                },
                visibleItemCount: 3,
                referenceValue: widget.initialVolume,
              ),
            
            const SizedBox(height: 16.0),
            
            // 欠減計算
            if (_movementMeasurement != null)
              SectionCard(
                title: '欠減計算(タンク移動)',
                icon: Icons.calculate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '移動数量: ${_movementMeasurement!.volume.toStringAsFixed(1)}L',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '蔵出し数量: ${widget.initialVolume.toStringAsFixed(1)}L',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4.0),
                    
                    // 計算ボタン
                    if (!_isCalculated)
                      ElevatedButton(
                        onPressed: _calculateMovement,
                        child: const Text('欠減計算'),
                      )
                    else
                      Text(
                        '欠減量: ${_shortageMovement.toStringAsFixed(1)}L (${_shortageMovementPercentage.toStringAsFixed(2)}%)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _shortageMovement < 0 ? Colors.red : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16.0),
            
            // 移動元タンク残量選択
            if (_sourceTankNumber != null && _isCalculated) ...[
              const SizedBox(height: 16.0),
              SectionCard(
                title: '移動元タンク残量選択',
                icon: Icons.water_drop_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 説明テキスト
                    Text(
                      '移動後に移動元タンクに残った量を選択してください',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    
                    // ラジオボタンで選択
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('残量なし (0L)'),
                            value: true,
                            groupValue: _isZeroRemaining,
                            onChanged: (value) {
                              setState(() {
                                _isZeroRemaining = true;
                                
                                // タンク情報からmax検尺値を取得
                                final tank = _tankDataService.getTank(_sourceTankNumber!);
                                final maxDipstick = tank?.maxDipstick ?? 2000.0;
                                
                                // 0Lの残量を表すMeasurementDataを作成
                                _remainingMeasurement = MeasurementData(
                                  volume: 0.0,
                                  dipstick: maxDipstick,
                                );
                                
                                // 移動前タンク総量の更新
                                _sourceInitialVolume = _movementMeasurement!.volume;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('残量データ選択'),
                            value: false,
                            groupValue: _isZeroRemaining,
                            onChanged: (value) {
                              setState(() {
                                _isZeroRemaining = false;
                                _remainingMeasurement = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    // 「残量データ選択」の場合のみ表示
                    if (!_isZeroRemaining)
                      TankVolumeSelector(
                        tankNumber: _sourceTankNumber!,
                        title: '',
                        showTitle: false,
                        useDipstickAsReference: false,
                        onMeasurementSelected: (measurement) {
                          setState(() {
                            _remainingMeasurement = measurement;
                            
                            // 移動前タンク総量の更新
                            _sourceInitialVolume = _movementMeasurement!.volume + measurement.volume;
                          });
                        },
                        visibleItemCount: 3,
                        referenceValue: 0.0,
                      ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16.0),
            
            // 移動前タンク総量表示
            if (_remainingMeasurement != null && _isCalculated)
              SectionCard(
                title: '移動前タンク総量',
                icon: Icons.water_drop_outlined,
                child: Text(
                  '${_sourceInitialVolume.toStringAsFixed(1)} L (移動量 + 残量)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            const SizedBox(height: 24.0),
            
            // 確定ボタン - タンク選択のバリデーションを追加
            if (_isCalculated && _movementMeasurement != null && 
                _destinationTankNumber != null && _destinationTankNumber!.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(_createMovementStageData());
                },
                icon: const Icon(Icons.check),
                label: const Text('記録して確定'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            
            const SizedBox(height: 16.0),
            
            // キャンセルボタン
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.cancel),
              label: const Text('キャンセル'),
            ),
          ],
        ),
      ),
    );
  }
}