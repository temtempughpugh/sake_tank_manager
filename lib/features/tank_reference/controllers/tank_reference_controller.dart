import 'package:flutter/material.dart';
import '../../../core/models/tank.dart';
import '../../../core/models/measurement_result.dart';
import '../../../core/models/approximation_pair.dart';
import '../../../core/services/tank_data_service.dart';
import '../../../core/services/calculation_service.dart';
import '../../../core/services/storage_service.dart';

/// タンク早見表のコントローラー
class TankReferenceController extends ChangeNotifier {
  /// タンクデータサービス
  final TankDataService _tankDataService = TankDataService();
  
  /// 計算サービス
  final CalculationService _calculationService = CalculationService();
  
  /// ストレージサービス
  final StorageService _storageService = StorageService();

  /// 選択されたタンク番号
  String? _selectedTank;
  
  /// 測定結果
  MeasurementResult? _result;
  
  /// 近似値ペアのリスト
  List<ApproximationPair> _approximationPairs = [];
  
  /// 検尺モードかどうか（trueなら検尺→容量、falseなら容量→検尺）
  bool _isDipstickMode = true;
  
  /// エラーメッセージ
  String? _errorMessage;

  /// 選択されたタンク番号を取得
  String? get selectedTank => _selectedTank;
  
  /// 測定結果を取得
  MeasurementResult? get result => _result;
  
  /// 近似値ペアのリストを取得
  List<ApproximationPair> get approximationPairs => _approximationPairs;
  
  /// 検尺モードかどうかを取得
  bool get isDipstickMode => _isDipstickMode;
  
  /// エラーメッセージを取得
  String? get errorMessage => _errorMessage;
  
  /// エラーがあるかどうか
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  /// 選択されたタンク情報を取得
  Tank? get selectedTankInfo {
    if (_selectedTank == null) {
      return null;
    }
    return _tankDataService.getTank(_selectedTank!);
  }

  /// 最後に選択されたタンクを取得
  String? get lastSelectedTank {
    return _storageService.getLastSelectedTank();
  }

  /// 初期データを読み込む
  Future<void> loadInitialData() async {
    try {
      // タンクデータの初期化
      if (!_tankDataService.isInitialized) {
        await _tankDataService.initialize();
      }
      
      // 入力モード（検尺/容量）の設定を読み込み
      _isDipstickMode = _storageService.getLastInputMode();
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'データの読み込みに失敗しました: $e';
      notifyListeners();
    }
  }

  /// タンクを選択
  void selectTank(String tankNumber) {
    _selectedTank = tankNumber;
    _errorMessage = null;
    _result = null;
    _approximationPairs = [];
    
    // 選択したタンクを保存
    _storageService.setLastSelectedTank(tankNumber);
    
    notifyListeners();
  }

  /// 検尺モードを設定
  void setDipstickMode(bool isDipstickMode) {
    _isDipstickMode = isDipstickMode;
    _errorMessage = null;
    _result = null;
    _approximationPairs = [];
    
    // 入力モードを保存
    _storageService.setLastInputMode(isDipstickMode);
    
    notifyListeners();
  }

  /// 検尺から容量を計算
  void calculateDipstickToVolume(double dipstick) {
    if (_selectedTank == null) {
      _errorMessage = 'タンクを選択してください';
      notifyListeners();
      return;
    }

    try {
      // 計算サービスで計算
      final result = _calculationService.dipstickToVolume(_selectedTank!, dipstick);
      
      if (result.hasError) {
        _errorMessage = result.errorMessage;
        _result = null;
      } else {
        _errorMessage = null;
        _result = result;
      }
      
      // 近似値は使わないので空に
      _approximationPairs = [];
      
      notifyListeners();
    } catch (e) {
      _errorMessage = '計算中にエラーが発生しました: $e';
      _result = null;
      _approximationPairs = [];
      notifyListeners();
    }
  }

  /// 容量から検尺を計算
  void calculateVolumeToDipstick(double volume) {
    if (_selectedTank == null) {
      _errorMessage = 'タンクを選択してください';
      notifyListeners();
      return;
    }

    try {
      // 計算サービスで計算
      final result = _calculationService.volumeToDipstick(_selectedTank!, volume);
      
      if (result.hasError) {
        _errorMessage = result.errorMessage;
        _result = null;
      } else {
        _errorMessage = null;
        _result = result;
      }
      
      // 近似値は使わないので空に
      _approximationPairs = [];
      
      notifyListeners();
    } catch (e) {
      _errorMessage = '計算中にエラーが発生しました: $e';
      _result = null;
      _approximationPairs = [];
      notifyListeners();
    }
  }

  /// エラーをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 結果をクリア
  void clearResult() {
    _result = null;
    _approximationPairs = [];
    _errorMessage = null;
    notifyListeners();
  }
}