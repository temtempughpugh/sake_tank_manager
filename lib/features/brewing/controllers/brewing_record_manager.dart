import '../../../core/services/storage_service.dart';
import '../models/brewing_record.dart';
import '../../bottling/models/bottling_info.dart';
import '../../bottling/controllers/bottling_manager.dart';

/// 醸造記録を管理するクラス
class BrewingRecordManager {
  /// ストレージのキー
  static const String _storageKey = 'brewing_records';
  
  /// ストレージサービス
  final StorageService _storageService = StorageService();
  
  /// 瓶詰め情報マネージャー
  final BottlingManager _bottlingManager = BottlingManager();
  
  /// 醸造記録リスト（キャッシュ）
  List<BrewingRecord> _records = [];
  
  /// 初期化済みフラグ
  bool _isInitialized = false;

  /// コンストラクタ
  BrewingRecordManager();

  /// 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadRecords();
    await _bottlingManager.initialize();
    _isInitialized = true;
  }

  /// 醸造記録の読み込み
  Future<void> _loadRecords() async {
    try {
      _records = _storageService.getObjectList<BrewingRecord>(
        _storageKey,
        (map) => BrewingRecord.fromMap(map),
      );
    } catch (e) {
      print('醸造記録の読み込みエラー: $e');
      _records = [];
    }
  }

  /// 醸造記録の保存
  Future<void> _saveRecords() async {
    try {
      await _storageService.setObjectList<BrewingRecord>(
        _storageKey,
        _records,
        (record) => record.toMap(),
      );
    } catch (e) {
      print('醸造記録の保存エラー: $e');
      throw Exception('醸造記録の保存に失敗しました');
    }
  }

  /// 全ての醸造記録を取得
  Future<List<BrewingRecord>> getAllRecords() async {
    if (!_isInitialized) await initialize();
    
    // 日付の新しい順にソート
    final sorted = List<BrewingRecord>.from(_records)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    return sorted;
  }

  /// 工程タイプ別の醸造記録を取得
  Future<List<BrewingRecord>> getRecordsByType(ProcessType processType) async {
    if (!_isInitialized) await initialize();
    
    final filtered = _records.where((record) => record.processType == processType).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    return filtered;
  }

  /// ID指定で醸造記録を取得
  Future<BrewingRecord?> getRecordById(String id) async {
    if (!_isInitialized) await initialize();
    
    try {
      return _records.firstWhere((record) => record.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 瓶詰めIDに紐づく醸造記録を取得
  Future<List<BrewingRecord>> getRecordsByBottlingId(String bottlingId) async {
    if (!_isInitialized) await initialize();
    
    final filtered = _records.where((record) => record.bottlingInfoId == bottlingId).toList()
      ..sort((a, b) => a.processType.index.compareTo(b.processType.index));
      
    return filtered;
  }

  /// タンク番号で醸造記録を取得
  Future<List<BrewingRecord>> getRecordsByTankNumber(String tankNumber) async {
    if (!_isInitialized) await initialize();
    
    final filtered = _records.where((record) => record.tankNumber == tankNumber).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    return filtered;
  }

  /// 瓶詰め情報を取得
  Future<BottlingInfo?> getBottlingInfo(String bottlingId) async {
    if (!_isInitialized) await initialize();
    
    final allBottlingInfos = await _bottlingManager.getAllBottlingInfos();
    try {
      return allBottlingInfos.firstWhere((info) => info.id == bottlingId);
    } catch (e) {
      return null;
    }
  }

  /// 醸造記録を追加
  Future<void> addRecord(BrewingRecord record) async {
    if (!_isInitialized) await initialize();
    
    _records.add(record);
    await _saveRecords();
  }

  /// 醸造記録を更新
  Future<void> updateRecord(BrewingRecord record) async {
    if (!_isInitialized) await initialize();
    
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index == -1) {
      throw Exception('更新する醸造記録が見つかりません: ${record.id}');
    }
    
    _records[index] = record;
    await _saveRecords();
  }

  /// 醸造記録を削除
  Future<void> deleteRecord(String id) async {
    if (!_isInitialized) await initialize();
    
    _records.removeWhere((record) => record.id == id);
    await _saveRecords();
  }

  /// 瓶詰め情報に関連する醸造記録を全て削除
  Future<void> deleteRecordsByBottlingId(String bottlingId) async {
    if (!_isInitialized) await initialize();
    
    _records.removeWhere((record) => record.bottlingInfoId == bottlingId);
    await _saveRecords();
  }

  /// 日付範囲で醸造記録を検索
  Future<List<BrewingRecord>> findRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!_isInitialized) await initialize();
    
    return _records
        .where((record) => 
            record.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) && 
            record.createdAt.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }
}