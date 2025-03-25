import '../../../core/services/storage_service.dart';
import '../models/bottling_info.dart';

/// 瓶詰め情報を管理するクラス
class BottlingManager {
  /// ストレージのキー
  static const String _storageKey = 'bottling_infos';
  
  /// ストレージサービス
  final StorageService _storageService = StorageService();
  
  /// 瓶詰め情報リスト（キャッシュ）
  List<BottlingInfo> _bottlingInfos = [];
  
  /// 初期化済みフラグ
  bool _isInitialized = false;

  /// コンストラクタ
  BottlingManager();

  /// 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadBottlingInfos();
    _isInitialized = true;
  }

  /// 瓶詰め情報の読み込み
  Future<void> _loadBottlingInfos() async {
    try {
      _bottlingInfos = _storageService.getObjectList<BottlingInfo>(
        _storageKey,
        (map) => BottlingInfo.fromMap(map),
      );
    } catch (e) {
      print('瓶詰め情報の読み込みエラー: $e');
      _bottlingInfos = [];
    }
  }

  /// 瓶詰め情報の保存
  Future<void> _saveBottlingInfos() async {
    try {
      await _storageService.setObjectList<BottlingInfo>(
        _storageKey,
        _bottlingInfos,
        (info) => info.toMap(),
      );
    } catch (e) {
      print('瓶詰め情報の保存エラー: $e');
      throw Exception('瓶詰め情報の保存に失敗しました');
    }
  }

  /// 全ての瓶詰め情報を取得
  Future<List<BottlingInfo>> getAllBottlingInfos() async {
    if (!_isInitialized) await initialize();
    
    // 日付の新しい順にソート
    final sorted = List<BottlingInfo>.from(_bottlingInfos)
      ..sort((a, b) => b.date.compareTo(a.date));
      
    return sorted;
  }

  /// 瓶詰め情報を追加
  Future<void> addBottlingInfo(BottlingInfo info) async {
    if (!_isInitialized) await initialize();
    
    _bottlingInfos.add(info);
    await _saveBottlingInfos();
  }

  /// 瓶詰め情報を更新
  Future<void> updateBottlingInfo(BottlingInfo info) async {
    if (!_isInitialized) await initialize();
    
    final index = _bottlingInfos.indexWhere((i) => i.id == info.id);
    if (index == -1) {
      throw Exception('更新する瓶詰め情報が見つかりません: ${info.id}');
    }
    
    _bottlingInfos[index] = info;
    await _saveBottlingInfos();
  }

  /// 瓶詰め情報を削除
  Future<void> deleteBottlingInfo(String id) async {
    if (!_isInitialized) await initialize();
    
    _bottlingInfos.removeWhere((info) => info.id == id);
    await _saveBottlingInfos();
  }

  /// 瓶詰め情報を完了済みとしてマーク
  Future<void> markBottlingInfoAsCompleted(String id) async {
    if (!_isInitialized) await initialize();
    
    final index = _bottlingInfos.indexWhere((info) => info.id == id);
    if (index == -1) {
      throw Exception('完了としてマークする瓶詰め情報が見つかりません: $id');
    }
    
    _bottlingInfos[index] = _bottlingInfos[index].markAsCompleted();
    await _saveBottlingInfos();
  }

  /// 酒名で瓶詰め情報を検索
  Future<List<BottlingInfo>> findBottlingInfosBySakeName(String sakeName) async {
    if (!_isInitialized) await initialize();
    
    return _bottlingInfos
        .where((info) => info.sakeName.contains(sakeName))
        .toList();
  }

  /// 日付範囲で瓶詰め情報を検索
  Future<List<BottlingInfo>> findBottlingInfosByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!_isInitialized) await initialize();
    
    return _bottlingInfos
        .where((info) => 
            info.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
            info.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }
}