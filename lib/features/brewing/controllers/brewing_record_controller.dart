import 'package:flutter/material.dart';
import '../../../core/models/measurement_data.dart';
import '../../../core/models/tank.dart';
import '../../../core/services/tank_data_service.dart';
import '../../../core/services/calculation_service.dart';
import '../../bottling/models/bottling_info.dart';
import '../models/brewing_record.dart';
import '../models/dilution_stage.dart';
import '../models/movement_stage.dart';
import '../models/bottling_info_update.dart';
import 'brewing_record_service.dart';

/// 記帳サポート画面の状態管理とビジネスロジックを担当するコントローラークラス
class BrewingRecordController extends ChangeNotifier {
  /// 記帳サービス
  final BrewingRecordService _recordService = BrewingRecordService();
  
  /// タンクデータサービス
  final TankDataService _tankDataService = TankDataService();
  
  /// 計算サービス
  final CalculationService _calculationService = CalculationService();
  
  /// 瓶詰め情報
  BottlingInfo? _bottlingInfo;
  
  /// 割水タンク番号
  String? _dilutionTankNumber;
  
  /// 割水後の測定データ
  MeasurementData? _finalMeasurement;
  
  /// 蔵出し(初期)の測定データ
  MeasurementData? _initialMeasurement;
  
  /// 割水前アルコール度数 (%)
  double _initialAlcoholPercentage = 0.0;
  
  /// 割水後アルコール度数 (%)
  double _finalAlcoholPercentage = 0.0;
  
  /// 割水量 (L)
  double _dilutionWaterAmount = 0.0;
  
  /// 瓶詰め総量 (L)
  double _bottlingTotalVolume = 0.0;
  
  /// 瓶詰め欠減量 (L)
  double _bottlingShortage = 0.0;
  
  /// 瓶詰め欠減率 (%)
  double _bottlingShortagePercentage = 0.0;
  
  /// タンク移動リスト
  List<MovementStageData> _movementStages = [];
  
  /// 読み込み中フラグ
  bool _isLoading = false;
  
  /// 計算完了フラグ
  bool _isCalculated = false;
  
  /// エラーメッセージ
  String? _errorMessage;

  /// 瓶詰め情報を取得
  BottlingInfo? get bottlingInfo => _bottlingInfo;
  
  /// 割水タンク番号を取得
  String? get dilutionTankNumber => _dilutionTankNumber;
  
  /// 割水後の測定データを取得
  MeasurementData? get finalMeasurement => _finalMeasurement;
  
  /// 蔵出しの測定データを取得
  MeasurementData? get initialMeasurement => _initialMeasurement;
  
  /// 割水前アルコール度数を取得
  double get initialAlcoholPercentage => _initialAlcoholPercentage;
  
  /// 割水後アルコール度数を取得
  double get finalAlcoholPercentage => _finalAlcoholPercentage;
  
  /// 割水量を取得
  double get dilutionWaterAmount => _dilutionWaterAmount;
  
  /// 瓶詰め総量を取得
  double get bottlingTotalVolume => _bottlingTotalVolume;
  
  /// 瓶詰め欠減量を取得
  double get bottlingShortage => _bottlingShortage;
  
  /// 瓶詰め欠減率を取得
  double get bottlingShortagePercentage => _bottlingShortagePercentage;
  
  /// タンク移動リストを取得
  List<MovementStageData> get movementStages => _movementStages;
  
  /// 読み込み中かどうかを取得
  bool get isLoading => _isLoading;
  
  /// 計算が完了しているかどうかを取得
  bool get isCalculated => _isCalculated;
  
  /// エラーメッセージを取得
  String? get errorMessage => _errorMessage;

  /// 割水タンク情報を取得
  Tank? get dilutionTank {
    if (_dilutionTankNumber == null) return null;
    return _tankDataService.getTank(_dilutionTankNumber!);
  }

  /// 初期化
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      await _recordService.initialize();
      
      if (!_tankDataService.isInitialized) {
        await _tankDataService.initialize();
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('初期化に失敗しました: $e');
    }
  }

  /// 瓶詰め情報を読み込み
  Future<void> loadBottlingInfo(String bottlingInfoId) async {
    _setLoading(true);
    _clearAll();
    
    try {
      final info = await _recordService.getBottlingInfo(bottlingInfoId);
      
      if (info == null) {
        _setError('瓶詰め情報が見つかりません: $bottlingInfoId');
        return;
      }
      
      _bottlingInfo = info;
      
      // 瓶詰め総量の計算
      _calculateBottlingTotalVolume();
      
      // 最終アルコール度数
      _finalAlcoholPercentage = info.alcoholPercentage;
      
      _setLoading(false);
    } catch (e) {
      _setError('瓶詰め情報の読み込みに失敗しました: $e');
    }
  }

  /// 割水タンクを設定
  void setDilutionTank(String tankNumber) {
    _dilutionTankNumber = tankNumber;
    _finalMeasurement = null;
    _initialMeasurement = null;
    _isCalculated = false;
    notifyListeners();
  }

  /// 割水後測定データを設定
  void setFinalMeasurement(MeasurementData measurement) {
    _finalMeasurement = measurement;
    
    // 欠減量の計算を更新
    if (_bottlingInfo != null) {
      _calculateBottlingShortage();
    }
    
    notifyListeners();
  }

  /// 初期（蔵出し）測定データを設定
  void setInitialMeasurement(MeasurementData measurement) {
    _initialMeasurement = measurement;
    
    // 計算を実行
    _calculateDilution();
    
    notifyListeners();
  }

  /// 初期アルコール度数を設定
  void setInitialAlcoholPercentage(double percentage) {
    if (percentage <= 0 || percentage > 100) {
      _setError('アルコール度数は0〜100%の範囲で入力してください');
      return;
    }
    
    _initialAlcoholPercentage = percentage;
    
    // 計算を実行
    _calculateDilution();
    
    notifyListeners();
  }

  /// タンク移動ステージを追加
  void addMovementStage(MovementStageData movementStage) {
    _movementStages.add(movementStage);
    notifyListeners();
  }

  /// タンク移動ステージを削除
  void removeMovementStage(int index) {
    if (index >= 0 && index < _movementStages.length) {
      _movementStages.removeAt(index);
      notifyListeners();
    }
  }

  /// 全タンク移動ステージをクリア
  void clearMovementStages() {
    _movementStages.clear();
    notifyListeners();
  }

  /// 割水計算を実行
  void _calculateDilution() {
    if (_initialMeasurement == null || _finalMeasurement == null) {
      return;
    }

    // 初期アルコール度数と最終アルコール度数のチェック
    if (_initialAlcoholPercentage <= 0) {
      _setError('初期アルコール度数を入力してください');
      return;
    }
    
    if (_finalAlcoholPercentage <= 0) {
      _setError('最終アルコール度数が正しく設定されていません');
      return;
    }
    
    // 初期アルコール度数が最終アルコール度数より低い場合はエラー
    if (_initialAlcoholPercentage <= _finalAlcoholPercentage) {
      _setError('初期アルコール度数は割水後アルコール度数より大きい値にしてください');
      return;
    }

    try {
      // 初期容量と最終容量
      final initialVolume = _initialMeasurement!.volume;
      final finalVolume = _finalMeasurement!.volume;
      
      // 割水量 = 最終容量 - 初期容量
      _dilutionWaterAmount = finalVolume - initialVolume;
      
      // 計算完了フラグを設定
      _isCalculated = true;
      
      // エラーをクリア
      _errorMessage = null;
      
      notifyListeners();
    } catch (e) {
      _setError('計算中にエラーが発生しました: $e');
    }
  }

  /// 瓶詰め総量を計算
  void _calculateBottlingTotalVolume() {
    if (_bottlingInfo == null) return;

    // 各瓶の容量 × 本数の合計
    double bottleVolume = _bottlingInfo!.totalVolume;
    
    // 詰め残し量（1.8L換算の本数 × 1.8L）
    double remainingVolume = _bottlingInfo!.remainingAmount * 1.8;
    
    // 総量 = 瓶詰め + 詰め残し
    _bottlingTotalVolume = bottleVolume + remainingVolume;
  }

  /// 瓶詰め欠減量を計算
  void _calculateBottlingShortage() {
    if (_finalMeasurement == null || _bottlingTotalVolume <= 0) return;

    // 欠減量 = 割水後容量 - 瓶詰め総量
    _bottlingShortage = _finalMeasurement!.volume - _bottlingTotalVolume;
    
    // 欠減率 = 欠減量 / 割水後容量 × 100
    _bottlingShortagePercentage = (_bottlingShortage / _finalMeasurement!.volume) * 100;
  }

  /// 瓶詰めデータを更新（アルコール度数）
  Future<BottlingInfoUpdate> updateBottlingInfo() async {
    if (_bottlingInfo == null) {
      throw Exception('瓶詰め情報が設定されていません');
    }
    
    if (!_isCalculated) {
      throw Exception('計算が完了していません');
    }

    // 更新前の情報
    final previousAlcoholPercentage = _bottlingInfo!.alcoholPercentage;
    final previousPureAlcoholAmount = _bottlingInfo!.pureAlcoholAmount;
    
    // 更新後の情報
    final updatedAlcoholPercentage = _finalAlcoholPercentage;
    final updatedPureAlcoholAmount = _bottlingTotalVolume * updatedAlcoholPercentage / 100;
    
    // 更新履歴を作成
    final update = BottlingInfoUpdate(
      previousAlcoholPercentage: previousAlcoholPercentage,
      updatedAlcoholPercentage: updatedAlcoholPercentage,
      previousPureAlcoholAmount: previousPureAlcoholAmount,
      updatedPureAlcoholAmount: updatedPureAlcoholAmount,
      updatedAt: DateTime.now(),
      updateReason: '記帳サポートによる割水計算の結果',
    );
    
    return update;
  }

  /// 記帳データを保存
  Future<void> saveBrewingRecord() async {
    if (_bottlingInfo == null) {
      throw Exception('瓶詰め情報が設定されていません');
    }
    
    if (_dilutionTankNumber == null) {
      throw Exception('割水タンクが選択されていません');
    }
    
    if (_initialMeasurement == null || _finalMeasurement == null) {
      throw Exception('測定データが不足しています');
    }
    
    if (!_isCalculated) {
      throw Exception('計算が完了していません');
    }

    try {
      // 瓶詰め情報の更新
      final bottlingUpdate = await updateBottlingInfo();
      
      // 割水ステージの作成
      final dilutionStage = DilutionStage(
        tankNumber: _dilutionTankNumber!,
        initialVolume: _initialMeasurement!.volume,
        initialDipstick: _initialMeasurement!.dipstick,
        initialAlcoholPercentage: _initialAlcoholPercentage,
        dilutionWaterAmount: _dilutionWaterAmount,
        finalVolume: _finalMeasurement!.volume,
        finalDipstick: _finalMeasurement!.dipstick,
        finalAlcoholPercentage: _finalAlcoholPercentage,
        bottlingTotalVolume: _bottlingTotalVolume,
        shortageDilution: _bottlingShortage,
        shortageDilutionPercentage: _bottlingShortagePercentage,
      );
      
      // タンク移動ステージのリストを作成
      final movementStages = _movementStages.map((stageData) {
        return MovementStage(
          id: stageData.id,
          sourceTankNumber: stageData.sourceTankNumber,
          destinationTankNumber: stageData.destinationTankNumber,
          movementVolume: stageData.movementVolume,
          sourceDipstick: stageData.sourceDipstick,
          destinationDipstick: stageData.destinationDipstick,
          sourceRemainingVolume: stageData.sourceRemainingVolume,
          sourceRemainingDipstick: stageData.sourceRemainingDipstick,
          sourceInitialVolume: stageData.sourceInitialVolume,
          shortageMovement: stageData.shortageMovement,
          shortageMovementPercentage: stageData.shortageMovementPercentage,
          processName: stageData.processName,
          notes: stageData.notes,
        );
      }).toList();
      
      // 記帳データの作成
      final record = BrewingRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bottlingInfoId: _bottlingInfo!.id,
        isBottlingInfoUpdated: true,
        bottlingUpdate: bottlingUpdate,
        dilutionStage: dilutionStage,
        movementStages: movementStages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 記帳データの保存
      await _recordService.addRecord(record);
      
      // 状態をリセット
      _clearAll();
      
      notifyListeners();
    } catch (e) {
      _setError('記帳データの保存に失敗しました: $e');
    }
  }

  /// 状態をすべてクリア
  void _clearAll() {
    _dilutionTankNumber = null;
    _finalMeasurement = null;
    _initialMeasurement = null;
    _initialAlcoholPercentage = 0.0;
    _finalAlcoholPercentage = 0.0;
    _dilutionWaterAmount = 0.0;
    _bottlingShortage = 0.0;
    _bottlingShortagePercentage = 0.0;
    _movementStages = [];
    _isCalculated = false;
    _errorMessage = null;
  }

  /// ローディング状態を設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// エラーを設定
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }
}

/// タンク移動ステージのデータクラス（画面間の共有用）
class MovementStageData {
  /// 移動ID
  String id;
  
  /// 移動元タンク番号
  String sourceTankNumber;
  
  /// 移動先タンク番号
  String destinationTankNumber;
  
  /// 移動量 (L)
  double movementVolume;
  
  /// 移動元検尺値 (mm)
  double sourceDipstick;
  
  /// 移動先検尺値 (mm)
  double destinationDipstick;
  
  /// 移動元タンク残量 (L)
  double sourceRemainingVolume;
  
  /// 移動元残量検尺値 (mm)
  double sourceRemainingDipstick;
  
  /// 移動前タンク総量 (L) - 移動量 + 残量
  double sourceInitialVolume;
  
  /// 欠減量 (L) - 移動量と次工程数量の差
  double shortageMovement;
  
  /// 欠減率 (%) - 欠減量 / 移動量 * 100
  double shortageMovementPercentage;
  
  /// 工程名（例: 火入れ、ろ過など）
  String? processName;
  
  /// 備考
  String? notes;

  /// コンストラクタ
  MovementStageData({
    required this.id,
    required this.sourceTankNumber,
    required this.destinationTankNumber,
    required this.movementVolume,
    required this.sourceDipstick,
    required this.destinationDipstick,
    required this.sourceRemainingVolume,
    required this.sourceRemainingDipstick,
    required this.sourceInitialVolume,
    required this.shortageMovement,
    required this.shortageMovementPercentage,
    this.processName,
    this.notes,
  });
}