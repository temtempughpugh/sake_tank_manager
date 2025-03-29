import 'package:flutter/material.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/tank_selector.dart';
import '../../../shared/widgets/tank_volume_selector.dart';
import '../../../core/models/measurement_data.dart';
import '../../../core/utils/error_handler.dart';
import '../controllers/brewing_record_controller.dart';

/// タンク移動追加画面
class TankMovementScreen extends StatefulWidget {
  /// 移動先タンク番号（通常は割水タンク）
  final String destinationTankNumber;
  
  /// 蔵出し量（次工程数量）
  final double initialVolume;
  
  /// 蔵出し検尺値
  final double initialDipstick;

  /// コンストラクタ
  const TankMovementScreen({
    Key? key,
    required this.destinationTankNumber,
    required this.initialVolume,
    required this.initialDipstick,
  }) : super(key: key);

  @override
  State<TankMovementScreen> createState() => _TankMovementScreenState();
}

class _TankMovementScreenState extends State<TankMovementScreen> {
  /// 移動元タンク番号
  String? _sourceTankNumber;
  
  /// 移動数量の測定データ
  MeasurementData? _movementMeasurement;
  
  /// 残量の測定データ
  MeasurementData? _remainingMeasurement;
  
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

  @override
  void initState() {
    super.initState();
    
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
    return MovementStageData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceTankNumber: _sourceTankNumber!,
      destinationTankNumber: widget.destinationTankNumber,
      movementVolume: _movementMeasurement!.volume,
      sourceDipstick: _movementMeasurement!.dipstick,
      destinationDipstick: widget.initialDipstick,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '移動元タンク:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TankSelector(
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
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16.0),
                  
                  // 移動先タンク表示
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '移動先タンク:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          child: Text(widget.destinationTankNumber),
                        ),
                      ),
                    ],
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
    visibleItemCount: 3, // 3つに変更
    referenceValue: widget.initialVolume, // 蔵出し量に近い順
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
            if (_sourceTankNumber != null && _isCalculated)
  TankVolumeSelector(
    tankNumber: _sourceTankNumber!,
    title: '移動元タンク残量選択',
    description: '移動後に移動元タンクに残った量を選択してください',
    useDipstickAsReference: false,
    onMeasurementSelected: (measurement) {
      setState(() {
        _remainingMeasurement = measurement;
        
        // 移動前タンク総量の更新
        _sourceInitialVolume = _movementMeasurement!.volume + measurement.volume;
      });
    },
    visibleItemCount: 3, // 3つに変更
    referenceValue: 0, // 0に近い残量を優先表示
  ),
            
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
            
            // 確定ボタン
            if (_isCalculated && _movementMeasurement != null)
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