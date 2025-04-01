// lib/features/brewing/controllers/brewing_record_service.dart
import '../../../core/services/storage_service.dart';
import '../models/brewing_record.dart';
import '../../bottling/models/bottling_info.dart';
import '../../bottling/controllers/bottling_manager.dart';

/// 記帳データの保存・読み込みを管理するサービスクラス
class BrewingRecordService {
  /// ストレージのキー
  static const String _storageKey = 'brewing_records';
  
  /// ストレージサービス
  final StorageService _storageService;
  
  /// 瓶詰め情報マネージャー
  final BottlingManager _bottlingManager;
  
  /// 記帳データリスト（キャッシュ）
  List<BrewingRecord> _records = [];
  
  /// 初期化済みフラグ
  bool _isInitialized = false;

  /// コンストラクタ - 依存サービスを注入
  BrewingRecordService(this._storageService, this._bottlingManager);

  /// 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadRecords();
    await _bottlingManager.initialize();
    _isInitialized = true;
  }

  /// 記帳データの読み込み
  Future<void> _loadRecords() async {
    try {
      _records = _storageService.getObjectList<BrewingRecord>(
        _storageKey,
        (map) => BrewingRecord.fromMap(map),
      );
    } catch (e) {
      print('記帳データの読み込みエラー: $e');
      _records = [];
    }
  }

  /// 記帳データの保存
  Future<void> _saveRecords() async {
    try {
      await _storageService.setObjectList<BrewingRecord>(
        _storageKey,
        _records,
        (record) => record.toMap(),
      );
    } catch (e) {
      print('記帳データの保存エラー: $e');
      throw Exception('記帳データの保存に失敗しました');
    }
  }

  /// 全ての記帳データを取得
  Future<List<BrewingRecord>> getAllRecords() async {
    if (!_isInitialized) await initialize();
    
    // 日付の新しい順にソート
    final sorted = List<BrewingRecord>.from(_records)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    return sorted;
  }

  /// 特定の瓶詰め情報に関連する記帳データを取得
  Future<List<BrewingRecord>> getRecordsByBottlingInfoId(String bottlingInfoId) async {
    if (!_isInitialized) await initialize();
    
    return _records
        .where((record) => record.bottlingInfoId == bottlingInfoId)
        .toList();
  }

  /// 記帳データを追加
  Future<void> addRecord(BrewingRecord record) async {
    if (!_isInitialized) await initialize();
    
    _records.add(record);
    await _saveRecords();
    
    // 瓶詰め情報の更新が含まれている場合は瓶詰め情報も更新
    if (record.isBottlingInfoUpdated && record.bottlingUpdate != null) {
      await _updateBottlingInfo(record);
    }
  }

  /// 記帳データを更新
  Future<void> updateRecord(BrewingRecord record) async {
  if (!_isInitialized) await initialize();
  
  final index = _records.indexWhere((r) => r.id == record.id);
  if (index == -1) {
    // 見つからない場合はエラーではなく新規追加として処理
    _records.add(record);
  } else {
    // 既存のレコードを更新
    _records[index] = record;
  }
  
  // 更新後必ず保存
  await _saveRecords();
  
  // 瓶詰め情報の更新も確実に実行
  if (record.isBottlingInfoUpdated && record.bottlingUpdate != null) {
    await _updateBottlingInfo(record);
  }
}

  /// 記帳データを削除
  Future<void> deleteRecord(String id) async {
    if (!_isInitialized) await initialize();
    
    _records.removeWhere((record) => record.id == id);
    await _saveRecords();
  }

  /// 瓶詰め情報を更新
  Future<void> _updateBottlingInfo(BrewingRecord record) async {
    final bottlingInfos = await _bottlingManager.getAllBottlingInfos();
    final bottlingInfo = bottlingInfos.firstWhere(
      (info) => info.id == record.bottlingInfoId,
      orElse: () => throw Exception('瓶詰め情報が見つかりません: ${record.bottlingInfoId}'),
    );
    
    // アルコール度数を更新
    final updatedInfo = bottlingInfo.copyWith(
      alcoholPercentage: record.bottlingUpdate!.updatedAlcoholPercentage,
    );
    
    await _bottlingManager.updateBottlingInfo(updatedInfo);
  }

  /// 瓶詰め情報の取得
  Future<BottlingInfo?> getBottlingInfo(String bottlingInfoId) async {
    await _bottlingManager.initialize();
    
    final bottlingInfos = await _bottlingManager.getAllBottlingInfos();
    try {
      return bottlingInfos.firstWhere((info) => info.id == bottlingInfoId);
    } catch (e) {
      return null;
    }
  }

  /// 未記帳の瓶詰め情報リストを取得
  Future<List<BottlingInfo>> getUnrecordedBottlingInfos() async {
    if (!_isInitialized) await initialize();
    
    final allBottlingInfos = await _bottlingManager.getAllBottlingInfos();
    final recordedInfoIds = _records.map((r) => r.bottlingInfoId).toSet();
    
    // 記帳済みでないものを抽出
    return allBottlingInfos
        .where((info) => !recordedInfoIds.contains(info.id))
        .toList();
  }
}