import 'package:flutter/material.dart';
import '../models/dilution_plan.dart';
import '../../../core/services/storage_service.dart';

/// 割水計画管理クラス
class DilutionPlanManager extends ChangeNotifier {
  /// ストレージキー
  static const String _storageKey = 'dilution_plans';

  /// ストレージサービス
  final StorageService _storageService = StorageService();

  /// 割水計画リスト
  List<DilutionPlan> _plans = [];
  
  /// 読み込み中フラグ
  bool _isLoading = false;

  /// 割水計画リストを取得
  List<DilutionPlan> get plans => _plans;
  
  /// 計画中の割水計画リストを取得（未完了）
  List<DilutionPlan> get activePlans => _plans
      .where((plan) => !plan.isCompleted)
      .toList();
  
  /// 完了済みの割水計画リストを取得
  List<DilutionPlan> get completedPlans => _plans
      .where((plan) => plan.isCompleted)
      .toList();
  
  /// 読み込み中かどうか
  bool get isLoading => _isLoading;

  /// 割水計画を追加
  Future<void> addPlan(DilutionPlan plan) async {
    _plans.add(plan);
    await _savePlans();
    notifyListeners();
  }

  /// 割水計画を更新
  Future<void> updatePlan(DilutionPlan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    
    if (index >= 0) {
      _plans[index] = plan;
      await _savePlans();
      notifyListeners();
    }
  }

  /// 割水計画を削除
  Future<void> deletePlan(DilutionPlan plan) async {
    _plans.removeWhere((p) => p.id == plan.id);
    await _savePlans();
    notifyListeners();
  }

  /// 割水計画を完了としてマーク
  Future<void> markPlanAsCompleted(DilutionPlan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    
    if (index >= 0) {
      _plans[index] = plan.markAsCompleted();
      await _savePlans();
      notifyListeners();
    }
  }

  /// 割水計画を読み込み
  Future<void> loadPlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      // SharedPreferencesの初期化
      if (!_storageService.containsKey(_storageKey)) {
        _plans = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // 保存された計画を読み込み
      _plans = _storageService.getObjectList(
        _storageKey,
        (map) => DilutionPlan.fromMap(map),
      );
      
      // 作成日の新しい順に並べ替え
      _plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('割水計画の読み込みエラー: $e');
      _plans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 割水計画を保存
  Future<void> _savePlans() async {
    try {
      await _storageService.setObjectList(
        _storageKey,
        _plans,
        (plan) => plan.toMap(),
      );
    } catch (e) {
      print('割水計画の保存エラー: $e');
      throw Exception('割水計画の保存に失敗しました: $e');
    }
  }

  /// 割水計画を全てクリア（テスト用）
  Future<void> clearAllPlans() async {
    _plans = [];
    await _storageService.remove(_storageKey);
    notifyListeners();
  }
}