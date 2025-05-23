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
  final TankDataService _tankDataService;
  
  /// 計算サービス
  final CalculationService _calculationService;
  
  /// ストレージサービス
  final StorageService _storageService;
  
  /// 割水計画マネージャー
  final DilutionPlanManager _planManager;

DilutionController({
    required TankDataService tankDataService,
    required CalculationService calculationService,
    required StorageService storageService,
    required DilutionPlanManager planManager,
  }) : 
    _tankDataService = tankDataService,
    _calculationService = calculationService,
    _storageService = storageService,
    _planManager = planManager;
  /// 選択されたタンク番号
  String? _selectedTank;
  
  /// 検尺モードかどうか（trueなら検尺、falseなら容量）
  bool _isUsingDipstick = true;

  /// 逆引きモードかどうか
  bool _isReverseMode = false;
  
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

  /// 逆引きモードかどうかを取得
  bool get isReverseMode => _isReverseMode;
  
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
      
      // 逆引きモードの設定を読み込み
      _isReverseMode = _storageService.getReverseMode();
      
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
    _result = null; // 結果もクリアする
    _approximationPairs = [];
    _inputApproximationPairs = [];
    
    // 入力モードを保存
    _storageService.setLastInputMode(isUsingDipstick);
    
    notifyListeners();
  }
  
  /// 編集モードを設定
  void setEditMode(DilutionPlan plan) {
    _isEditMode = true;
    _editPlanId = plan.id;
    
    // 計画の結果データを設定
    _result = plan.result;  
    
    // タンク選択
    if (_selectedTank != plan.result.tankNumber) {
      selectTank(plan.result.tankNumber);
    }
    
    // 測定結果を初期化
    _measurementResult = MeasurementResult(
      dipstick: plan.result.initialDipstick,
      volume: plan.result.initialVolume,
      isExactMatch: true
    );
    
    // 最終容量の近似値を検索（重要）
    if (_selectedTank != null) {
      _approximationPairs = _calculationService.findApproximateVolumes(
        _selectedTank!,
        plan.result.finalVolume,
      );
    }
    
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

    if (_measurementResult == null) {
      _errorMessage = '有効な測定結果がありません';
      notifyListeners();
      return;
    }

    try {
      // 初期容量と初期検尺値を取得（測定結果から）
      double initialDipstick = _measurementResult!.dipstick;
      double initialVolume = _measurementResult!.volume;
      
      // アルコール量保存の原理に基づく計算
      double waterAmount = initialVolume * (initialAlcoholPercentage / targetAlcoholPercentage) - initialVolume;
      double finalVolume = initialVolume + waterAmount;
      
      // 最終検尺値の計算
      final dipstickResult = _calculationService.volumeToDipstick(_selectedTank!, finalVolume);
      if (dipstickResult.hasError) {
        _errorMessage = dipstickResult.errorMessage;
        _result = null;
        _approximationPairs = [];
        notifyListeners();
        return;
      }
      
      double finalDipstick = dipstickResult.dipstick;
      
      // 最終アルコール度数
      double finalAlcohol = (initialVolume * initialAlcoholPercentage) / finalVolume;
      
      // 結果オブジェクトの作成
      _result = DilutionResult(
        tankNumber: _selectedTank!,
        initialVolume: initialVolume,
        initialDipstick: initialDipstick,
        initialAlcoholPercentage: initialAlcoholPercentage,
        targetAlcoholPercentage: targetAlcoholPercentage,
        waterAmount: waterAmount,
        finalVolume: finalVolume,
        finalDipstick: finalDipstick,
        finalAlcoholPercentage: finalAlcohol,
        sakeName: sakeName,
        personInCharge: personInCharge,
      );
      
      // 近似値検索
      _approximationPairs = _calculationService.findApproximateVolumes(
        _selectedTank!,
        finalVolume,
      );
      
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
      
      // デバッグ用
      print('DEBUG: 近似値選択 - 選択された容量: $volume L, 対応する検尺値: ${dipstickResult.dipstick} mm');
      print('DEBUG: 更新前 - _isReverseMode: $_isReverseMode');
      
      if (_isReverseMode) {
        // 逆引きモード: 蔵出し量を更新
        final waterAmount = currentResult.finalVolume - volume;
        
        // 目標アルコール度数を再計算
        final updatedAlcohol = (volume * currentResult.initialAlcoholPercentage) / currentResult.finalVolume;
        
        _result = DilutionResult(
          tankNumber: currentResult.tankNumber,
          initialVolume: volume, // 選択した蔵出し量
          initialDipstick: dipstickResult.dipstick, // 対応する蔵出し検尺値
          initialAlcoholPercentage: currentResult.initialAlcoholPercentage,
          targetAlcoholPercentage: currentResult.targetAlcoholPercentage,
          waterAmount: waterAmount,
          finalVolume: currentResult.finalVolume, // 割水後量（固定）
          finalDipstick: currentResult.finalDipstick, // 割水後検尺（固定）
          finalAlcoholPercentage: updatedAlcohol, // 再計算した最終アルコール度数
          sakeName: currentResult.sakeName,
          personInCharge: currentResult.personInCharge,
        );
        
        print('DEBUG: 逆引きモード更新後 - 蔵出し量: ${_result!.initialVolume} L, 蔵出し検尺値: ${_result!.initialDipstick} mm, 最終アルコール度数: ${_result!.finalAlcoholPercentage}%');
      } else {
        // 通常モード: 最終容量を更新
        final finalAlcohol = _calculationService.calculateFinalAlcohol(
          currentResult.initialVolume,
          currentResult.initialAlcoholPercentage,
          volume,
        );
        final waterAmount = volume - currentResult.initialVolume;
        
        _result = DilutionResult(
          tankNumber: currentResult.tankNumber,
          initialVolume: currentResult.initialVolume, // 蔵出し量（固定）
          initialDipstick: currentResult.initialDipstick, // 蔵出し検尺（固定）
          initialAlcoholPercentage: currentResult.initialAlcoholPercentage,
          targetAlcoholPercentage: currentResult.targetAlcoholPercentage,
          waterAmount: waterAmount,
          finalVolume: volume, // 選択した最終容量
          finalDipstick: dipstickResult.dipstick, // 対応する最終検尺値
          finalAlcoholPercentage: finalAlcohol,
          sakeName: currentResult.sakeName,
          personInCharge: currentResult.personInCharge,
        );
        
        print('DEBUG: 通常モード更新後 - 最終容量: ${_result!.finalVolume} L, 最終検尺値: ${_result!.finalDipstick} mm');
      }
      
      // 選択した近似値に対して選択状態を更新
      _updateApproximationPairsSelectionState(volume);
      
      notifyListeners();
    } catch (e) {
      print('近似値からの更新エラー: $e');
    }
  }

  /// 近似値リストの選択状態を更新する新しいメソッド
  void _updateApproximationPairsSelectionState(double selectedVolume) {
    // 既存の近似値リストをベースに新しいリストを作成
    List<ApproximationPair> updatedPairs = [];
    
    for (var pair in _approximationPairs) {
      // 選択された容量と一致するかチェック
      bool isSelected = pair.data.volume == selectedVolume;
      
      // 選択されたアイテムならisClosestをtrueに設定
      if (isSelected) {
        updatedPairs.add(ApproximationPair(
          data: pair.data,
          difference: pair.difference,
          isExactMatch: pair.isExactMatch,
          isClosest: true, // 選択されたアイテムをハイライト
        ));
      } else {
        // 選択されていないアイテムはisClosestをfalseに設定
        updatedPairs.add(ApproximationPair(
          data: pair.data,
          difference: pair.difference,
          isExactMatch: pair.isExactMatch,
          isClosest: false,
        ));
      }
    }
    
    // 更新された近似値リストを設定
    _approximationPairs = updatedPairs;
  }

  /// 割水計画を保存
  Future<void> saveDilutionPlan([String? planId]) async {
    if (_result == null || _result!.hasError) {
      throw Exception('有効な割水計算結果がありません');
    }

    try {
      await _planManager.initialize();
      
      if (_isEditMode && planId != null) {
        final plan = await _planManager.getPlanById(planId);
        if (plan == null) {
          throw Exception('更新する計画が見つかりません');
        }
        
        // 元の計画を更新
        final updatedPlan = DilutionPlan(
          id: plan.id,
          result: _result!,
          createdAt: plan.createdAt,
          isCompleted: plan.isCompleted,
          completedAt: plan.completedAt,
        );
        
        print('計画更新: 元容量=${plan.result.finalVolume}, 新容量=${_result!.finalVolume}');
        await _planManager.updatePlan(updatedPlan);
      } else {
        final plan = DilutionPlan(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          result: _result!,
          createdAt: DateTime.now(),
        );
        await _planManager.addPlan(plan);
        
        print('新しい計画が追加されました: ${plan.id}, タンク: ${plan.result.tankNumber}');
      }
    } catch (e) {
      print('割水計画の保存エラー: $e');
      throw Exception('割水計画の保存に失敗しました: $e');
    }
  }

  /// 逆引きモードを設定
  void setReverseMode(bool isReverse) {
    if (_isReverseMode != isReverse) {
      _isReverseMode = isReverse;
      _errorMessage = null;
      _measurementResult = null;
      _result = null;
      _approximationPairs = [];
      _inputApproximationPairs = [];
      
      // 設定を保存
      _storageService.setReverseMode(isReverse);
      
      notifyListeners();
    }
  }

  /// 逆引き割水計算を実行
  void calculateReverseDilution({
    required double finalValue,
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
      // 逆引き割水計算の実行
      final result = _calculationService.calculateReverseDilution(
        tankNumber: _selectedTank!,
        finalValue: finalValue,
        isUsingDipstick: _isUsingDipstick,
        initialAlcoholPercentage: initialAlcoholPercentage,
        targetAlcoholPercentage: targetAlcoholPercentage,
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
        
        // 蔵出し量の近似値を検索
        _approximationPairs = _calculationService.findApproximateVolumes(
          _selectedTank!, 
          result.initialVolume
        );
        
        // 初期状態での選択状態を設定
        _updateApproximationPairsSelectionState(result.initialVolume);
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = '計算中にエラーが発生しました: $e';
      _result = null;
      _approximationPairs = [];
      notifyListeners();
    }
  }

  /// 結果をクリア
  void clearResult() {
    _result = null;
    _approximationPairs = [];
    _errorMessage = null;
    notifyListeners();
  }
}