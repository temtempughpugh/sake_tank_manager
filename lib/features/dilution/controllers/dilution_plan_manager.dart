import '../../../core/services/storage_service.dart';
import '../models/dilution_plan.dart';

/// 割水計画を管理するクラス
class DilutionPlanManager {
  /// ストレージのキー
  static const String _storageKey = 'dilution_plans';
  
  /// ストレージサービス
  final StorageService _storageService = StorageService();
  
  /// 計画リスト（キャッシュ）
  List<DilutionPlan> _plans = [];
  
  /// 初期化済みフラグ
  bool _isInitialized = false;

  /// コンストラクタ
  DilutionPlanManager();

  /// 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadPlans();
    _isInitialized = true;
  }

  /// 計画の読み込み
  Future<void> _loadPlans() async {
    try {
      _plans = _storageService.getObjectList<DilutionPlan>(
        _storageKey,
        (map) => DilutionPlan.fromMap(map),
      );
    } catch (e) {
      print('割水計画の読み込みエラー: $e');
      _plans = [];
    }
  }

  /// 計画の保存
  Future<void> _savePlans() async {
    try {
      await _storageService.setObjectList<DilutionPlan>(
        _storageKey,
        _plans,
        (plan) => plan.toMap(),
      );
    } catch (e) {
      print('割水計画の保存エラー: $e');
      throw Exception('割水計画の保存に失敗しました');
    }
  }

  /// 全ての計画を取得
  Future<List<DilutionPlan>> getAllPlans() async {
    if (!_isInitialized) await initialize();
    return List.unmodifiable(_plans);
  }

  /// 実行中の計画を取得
  Future<List<DilutionPlan>> getActivePlans() async {
    if (!_isInitialized) await initialize();
    return List.unmodifiable(_plans.where((plan) => !plan.isCompleted));
  }

  /// 完了済みの計画を取得
  Future<List<DilutionPlan>> getCompletedPlans() async {
    if (!_isInitialized) await initialize();
    return List.unmodifiable(_plans.where((plan) => plan.isCompleted));
  }

  /// 計画を追加
  Future<void> addPlan(DilutionPlan plan) async {
    if (!_isInitialized) await initialize();
    
    _plans.add(plan);
    await _savePlans();
  }

  /// 計画を更新
  Future<void> updatePlan(DilutionPlan plan) async {
    if (!_isInitialized) await initialize();
    
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index == -1) {
      throw Exception('更新する計画が見つかりません: ${plan.id}');
    }
    
    _plans[index] = plan;
    await _savePlans();
  }

  /// 計画を削除
  Future<void> deletePlan(String planId) async {
    if (!_isInitialized) await initialize();
    
    _plans.removeWhere((plan) => plan.id == planId);
    await _savePlans();
  }

  /// 計画を完了済みとしてマーク
  Future<void> markPlanAsCompleted(String planId) async {
    if (!_isInitialized) await initialize();
    
    final index = _plans.indexWhere((p) => p.id == planId);
    if (index == -1) {
      throw Exception('完了としてマークする計画が見つかりません: $planId');
    }
    
    _plans[index] = _plans[index].markAsCompleted();
    await _savePlans();
  }

  /// タンク番号で計画を検索
  Future<List<DilutionPlan>> findPlansByTank(String tankNumber) async {
    if (!_isInitialized) await initialize();
    
    return List.unmodifiable(
      _plans.where((plan) => plan.result.tankNumber == tankNumber),
    );
  }
}