import 'package:flutter/material.dart';
import '../../../core/models/tank.dart';
import '../../../core/models/measurement_result.dart';
import '../../../core/models/dilution_result.dart';
import '../../../core/models/approximation_pair.dart';
import '../../../core/services/tank_data_service.dart';
import '../../../core/services/calculation_service.dart';
import '../../../core/services/storage_service.dart';
import 'dilution_plan_manager.dart';
import '../models/dilution_plan.dart';

/// 割水計算のコントローラー
class DilutionController extends ChangeNotifier {
  /// タンクデータサービス
  final TankDataService _tankDataService = TankDataService();
  
  /// 計算サービス
  final CalculationService _calculationService = CalculationService();
  
  /// ストレージサービス
  final StorageService _storageService = StorageService();
  
  /// 割水計画マネージャー
  final DilutionPlanManager _planManager = DilutionPlanManager();

  /// 選択されたタンク番号
  String? _selectedTank;
  
  /// 検尺モードかどうか（trueなら検尺、falseなら容量）
  bool _isUsingDipstick = true;
  
  /// 測定結果（検尺⇔容量変換用）
  MeasurementResult? _measurementResult;
  
  /// 割水計算結果
  DilutionResult? _result;
  
  /// 近似値ペアのリスト（入力時用）
  List<ApproximationPair> _inputApproximationPairs = [];
  
  /// 近似値ペアのリスト（結果容量用）
  List<ApproximationPair> _approximationPairs = [];
  
  /// エラーメッセージ
  String? _errorMessage;
  
  /// 編集中の計画ID
  String? _editPlanId;
  
  /// 編集モードかどうか
  bool _isEditMode = false;

  /// 選択されたタンク番号を取得
  String? get selectedTank => _selectedTank;
  
  /// 検尺モードかどうかを取得
  bool get isUsingDipstick => _isUsingDipstick;
  
  /// 検尺モードかどうかを取得（別名）
  bool get isDipstickMode => _isUsingDipstick;
  
  /// 測定結果を取得
  MeasurementResult? get measurementResult => _measurementResult;
  
  /// 割水計算結果を取得
  DilutionResult? get result => _result;
  
  /// 入力用近似値ペアのリストを取得
  List<ApproximationPair> get inputApproximationPairs => _inputApproximationPairs;
  
  /// 結果用近似値ペアのリストを取得
  List<ApproximationPair> get approximationPairs => _approximationPairs;
  
  /// エラーメッセージを取得
  String? get errorMessage => _errorMessage;
  
  /// エラーがあるかどうか
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  
  /// 編集モードかどうかを取得
  bool get isEditMode => _isEditMode;

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
      _isUsingDipstick = _storageService.getLastInputMode();
      
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
    _measurementResult = null;
    _result = null;
    _approximationPairs = [];
    _inputApproximationPairs = [];
    
    // 選択したタンクを保存
    _storageService.setLastSelectedTank(tankNumber);
    
    notifyListeners();
  }

  /// 検尺/容量モードを設定
  void setUsingDipstick(bool isUsingDipstick) {
    _isUsingDipstick = isUsingDipstick;
    _errorMessage = null;
    _measurementResult = null;
    _inputApproximationPairs = [];
    
    // 入力モードを保存
    _storageService.setLastInputMode(isUsingDipstick);
    
    notifyListeners();
  }
  
  /// 編集モードを設定
  void setEditMode(DilutionPlan plan) {
    _isEditMode = true;
    _editPlanId = plan.id;
    notifyListeners();
  }

  /// 検尺値から測定結果を更新
  void updateMeasurementFromDipstick(double dipstick) {
    if (_selectedTank == null) {
      return;
    }

    try {
      // 検尺→容量変換
      final result = _calculationService.dipstickToVolume(_selectedTank!, dipstick);
      
      if (result.hasError) {
        _errorMessage = result.errorMessage;
        _measurementResult = null;
        _inputApproximationPairs = [];
      } else {
        _errorMessage = null;
        _measurementResult = result;
        
        // 近似値検索
        _inputApproximationPairs = _calculationService.findApproximateDipsticks(
          _selectedTank!, 
          dipstick
        );
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = '計算エラー: $e';
      _measurementResult = null;
      _inputApproximationPairs = [];
      notifyListeners();
    }
  }

  /// 容量から測定結果を更新
  void updateMeasurementFromVolume(double volume) {
    if (_selectedTank == null) {
      return;
    }

    try {
      // 容量→検尺変換
      final result = _calculationService.volumeToDipstick(_selectedTank!, volume);
      
      if (result.hasError) {
        _errorMessage = result.errorMessage;
        _measurementResult = null;
        _inputApproximationPairs = [];
      } else {
        _errorMessage = null;
        _measurementResult = result;
        
        // 近似値検索
        _inputApproximationPairs = _calculationService.findApproximateVolumes(
          _selectedTank!, 
          volume
        );
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = '計算エラー: $e';
      _measurementResult = null;
      _inputApproximationPairs = [];
      notifyListeners();
    }
  }

  /// 近似値からの入力更新
  void updateFromInputApproximation(ApproximationPair pair) {
    if (_selectedTank == null) {
      return;
    }

    try {
      if (_isUsingDipstick) {
        // 検尺値から測定結果を更新
        updateMeasurementFromDipstick(pair.data.dipstick);
      } else {
        // 容量から測定結果を更新
        updateMeasurementFromVolume(pair.data.volume);
      }
      
      notifyListeners();
    } catch (e) {
      print('近似値からの入力更新エラー: $e');
    }
  }

  /// 割水計算を実行
  void calculateDilution({
    required double initialValue,
    required double initialAlcoholPercentage,
    required double targetAlcoholPercentage,
    String? sakeName,
    String? personInCharge,
  }) {
    if (_selectedTank == null) {
      _errorMessage = 'タンクを選択してください';
      notifyListeners();
      return;
    }

    try {
      // 割水計算を実行
      final result = _calculationService.calculateDilution(
        tankNumber: _selectedTank!,
        initialValue: initialValue,
        isUsingDipstick: _isUsingDipstick,
        initialAlcohol: initialAlcoholPercentage,
        targetAlcohol: targetAlcoholPercentage,
        sakeName: sakeName,
        personInCharge: personInCharge,
      );
      
      if (result.hasError) {
        _errorMessage = result.errorMessage;
        _result = null;
        _approximationPairs = [];
      } else {
        _errorMessage = null;
        _result = result;
        
        // 常に近似値検索を実行（完全一致でも行う）
        _approximationPairs = _calculationService.findApproximateVolumes(
          _selectedTank!,
          result.finalVolume,
        );
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = '計算中にエラーが発生しました: $e';
      _result = null;
      _approximationPairs = [];
      notifyListeners();
    }
  }

  /// 近似値から結果を更新
  void updateFromApproximateVolume(double volume) {
    if (_result == null || _selectedTank == null) {
      return;
    }

    try {
      final currentResult = _result!;
      final dipstickResult = _calculationService.volumeToDipstick(_selectedTank!, volume);
      
      if (dipstickResult.hasError) {
        print('Error in volumeToDipstick: ${dipstickResult.errorMessage}');
        return;
      }
      
      final finalAlcohol = _calculationService.calculateFinalAlcohol(
        currentResult.initialVolume,
        currentResult.initialAlcoholPercentage,
        volume,
      );
      final waterAmount = volume - currentResult.initialVolume;
      
      _result = DilutionResult(
        tankNumber: currentResult.tankNumber,
        initialVolume: currentResult.initialVolume,
        initialDipstick: currentResult.initialDipstick,
        initialAlcoholPercentage: currentResult.initialAlcoholPercentage,
        targetAlcoholPercentage: currentResult.targetAlcoholPercentage,
        waterAmount: waterAmount,
        finalVolume: volume,
        finalDipstick: dipstickResult.dipstick,
        finalAlcoholPercentage: finalAlcohol,
        sakeName: currentResult.sakeName,
        personInCharge: currentResult.personInCharge,
      );
      
      // ここを修正: toJson() → toMap()
      print('Updated result after approximation: ${_result!.toMap()}');
      notifyListeners();
    } catch (e) {
      print('近似値からの更新エラー: $e');
    }
  }

  Future<void> saveDilutionPlan([String? planId]) async {
    if (_result == null || _result!.hasError) {
      throw Exception('有効な割水計算結果がありません');
    }

    try {
      // ここを修正: toJson() → toMap()
      print('Saving result: ${_result!.toMap()}');
      
      if (_isEditMode && planId != null) {
        final plan = await _planManager.getPlanById(planId);
        if (plan == null) {
          throw Exception('更新する計画が見つかりません');
        }
        
        final updatedPlan = plan.copyWith(result: _result!);
        await _planManager.updatePlan(updatedPlan);
      } else {
        final plan = DilutionPlan(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          result: _result!,
          createdAt: DateTime.now(),
        );
        await _planManager.addPlan(plan);
      }
    } catch (e) {
      throw Exception('割水計画の保存に失敗しました: $e');
    }
  }

  /// 結果をクリア
  void clearResult() {
    _measurementResult = null;
    _result = null;
    _approximationPairs = [];
    _inputApproximationPairs = [];
    _errorMessage = null;
    notifyListeners();
  }
}