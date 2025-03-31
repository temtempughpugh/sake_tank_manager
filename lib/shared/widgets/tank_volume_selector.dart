import 'package:flutter/material.dart';
import '../../core/models/measurement_data.dart';
import '../../core/models/tank.dart';
import '../../core/services/tank_data_service.dart';
import 'scroll_selector.dart';

class TankVolumeSelector extends StatefulWidget {
  /// タンク番号
  final String tankNumber;
  
  /// 現在選択されている検尺値 (mm)
  final double? selectedDipstick;
  
  /// 現在選択されている容量 (L)
  final double? selectedVolume;
  
  /// 選択時の検尺値基準かどうか (trueなら検尺値基準、falseなら容量基準)
  final bool useDipstickAsReference;
  
  /// 選択された時のコールバック
  final void Function(MeasurementData) onMeasurementSelected;
  
  /// スクロールセレクターの見出し
  final String title;
  
  /// スクロールセレクターの説明文
  final String? description;
  
  /// スクロールセレクターの表示数
  final int visibleItemCount;
  
  /// タイトル表示するかどうか
  final bool showTitle;
  
  /// ウィジェットの幅
  final double? width;
  
  /// 目標となる基準値（並び替えに使用）
  final double? referenceValue;

  /// コンストラクタ
  const TankVolumeSelector({
    Key? key,
    required this.tankNumber,
    this.selectedDipstick,
    this.selectedVolume,
    this.useDipstickAsReference = true,
    required this.onMeasurementSelected,
    required this.title,
    this.description,
    this.visibleItemCount = 3,
    this.showTitle = true,
    this.width,
    this.referenceValue,
  }) : assert(selectedDipstick != null || selectedVolume != null || !useDipstickAsReference,
            "Either selectedDipstick or selectedVolume must be provided"),
      super(key: key);
      
  @override
  State<TankVolumeSelector> createState() => _TankVolumeSelectorState();
}

class _TankVolumeSelectorState extends State<TankVolumeSelector> {
  final TankDataService _tankDataService = TankDataService();
  List<MeasurementData> _measurements = [];
  MeasurementData? _selectedMeasurement;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTankData();
  }

  @override
  void didUpdateWidget(TankVolumeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // タンク番号が変わった場合は再読み込み
    if (widget.tankNumber != oldWidget.tankNumber) {
      _loadTankData();
    } else if ((widget.selectedDipstick != oldWidget.selectedDipstick && widget.useDipstickAsReference) ||
               (widget.selectedVolume != oldWidget.selectedVolume && !widget.useDipstickAsReference)) {
      // 選択値が変わった場合は選択項目を更新
      _updateSelectedMeasurement();
    }
  }

  /// タンクデータを読み込む
  Future<void> _loadTankData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // タンクデータが初期化されていなければ初期化
      if (!_tankDataService.isInitialized) {
        await _tankDataService.initialize();
      }

      // タンク情報を取得
      final tank = _tankDataService.getTank(widget.tankNumber);
      
      if (tank != null) {
        setState(() {
          // 測定データを取得して常に容量の多い順（検尺値の小さい順）にソート
          _measurements = List.from(tank.measurements);
          _measurements.sort((a, b) => b.volume.compareTo(a.volume)); // 容量の多い順
          
          // 現在の選択を更新（目標値があればそれに近いものが選ばれる）
          _updateSelectedMeasurement();
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _measurements = [];
          _selectedMeasurement = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('タンクデータの読み込みエラー: $e');
      setState(() {
        _measurements = [];
        _selectedMeasurement = null;
        _isLoading = false;
      });
    }
  }

  /// 選択中の測定データを更新
  void _updateSelectedMeasurement() {
    if (_measurements.isEmpty) {
      _selectedMeasurement = null;
      return;
    }

    // 優先順位で選択：
    // 1. 既に選択された検尺/容量値がある場合はそれに最も近いものを選択
    // 2. なければ目標値(referenceValue)に最も近いものを選択
    // 3. それもなければ先頭（最大容量）のデータを選択
    
    if (widget.useDipstickAsReference && widget.selectedDipstick != null) {
      // 検尺値に最も近い測定データを探す
      _selectedMeasurement = _findClosestMeasurementByDipstick(widget.selectedDipstick!);
    } else if (!widget.useDipstickAsReference && widget.selectedVolume != null) {
      // 容量に最も近い測定データを探す
      _selectedMeasurement = _findClosestMeasurementByVolume(widget.selectedVolume!);
    } else if (widget.referenceValue != null) {
      // 目標値に最も近い測定データを探す
      _selectedMeasurement = _findClosestMeasurementByVolume(widget.referenceValue!);
      
      // 目標値に近いアイテムを中央に表示するためのスクロール位置調整
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final index = _measurements.indexOf(_selectedMeasurement!);
        if (index >= 0) {
          // ここでScrollSelectorに値を設定
        }
      });
    } else {
      // デフォルトは先頭の測定データ（最大容量）
      _selectedMeasurement = _measurements.first;
    }
  }

  /// 検尺値に最も近い測定データを探す
  MeasurementData _findClosestMeasurementByDipstick(double dipstick) {
    return _measurements.reduce((closest, current) {
      final closestDiff = (closest.dipstick - dipstick).abs();
      final currentDiff = (current.dipstick - dipstick).abs();
      return currentDiff < closestDiff ? current : closest;
    });
  }

  /// 容量に最も近い測定データを探す
  MeasurementData _findClosestMeasurementByVolume(double volume) {
    return _measurements.reduce((closest, current) {
      final closestDiff = (closest.volume - volume).abs();
      final currentDiff = (current.volume - volume).abs();
      return currentDiff < closestDiff ? current : closest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル表示（オプション）
            if (widget.showTitle) ...[
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
            ],
            
            // 説明文（オプション）
            if (widget.description != null) ...[
              Text(
                widget.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8.0),
            ],
            
            // ローディング表示
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            // データがない場合
            else if (_measurements.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'タンクデータがありません',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            // スクロールセレクター
            else
              ScrollSelector<MeasurementData>(
                items: _measurements,
                selectedItem: _selectedMeasurement,
                labelBuilder: (data) => '${data.volume.toStringAsFixed(1)}',
                detailBuilder: (data) => '${data.dipstick.toInt()} mm',
                onItemSelected: (data) {
                  setState(() {
                    _selectedMeasurement = data;
                  });
                  widget.onMeasurementSelected(data);
                },
                visibleItemCount: widget.visibleItemCount,
                width: widget.width,
                selectedColor: Theme.of(context).colorScheme.primary,
                selectedTextColor: Theme.of(context).colorScheme.onPrimary,
                unselectedTextColor: Theme.of(context).colorScheme.onSurface,
              ),
          ],
        ),
      ),
    );
  }
}