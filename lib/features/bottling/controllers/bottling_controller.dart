import 'package:flutter/material.dart';
import '../models/bottling_info.dart';
import 'bottling_manager.dart';

/// 瓶詰め情報入力コントローラー
class BottlingController extends ChangeNotifier {
  /// 瓶詰め情報マネージャー
  final BottlingManager _bottlingManager = BottlingManager();
  
  /// 編集中の瓶詰め情報
  BottlingInfo? _currentBottlingInfo;
  
  /// 編集中の瓶種リスト
  final List<BottleEntry> _bottleEntries = [];
  
  /// 日付
  DateTime _date = DateTime.now();
  
  /// 酒名
  String _sakeName = '';
  
  /// アルコール度数
  double _alcoholPercentage = 0.0;
  
  /// 品温
  double? _temperature;
  
  /// 詰残量
  double _remainingAmount = 0.0;
  
  /// エラーメッセージ
  String? _errorMessage;
  
  /// 更新モードかどうか（trueなら更新、falseなら新規作成）
  bool _isUpdateMode = false;

  /// 日付を取得
  DateTime get date => _date;
  
  /// 酒名を取得
  String get sakeName => _sakeName;
  
  /// アルコール度数を取得
  double get alcoholPercentage => _alcoholPercentage;
  
  /// 品温を取得
  double? get temperature => _temperature;
  
  /// 詰残量を取得
  double get remainingAmount => _remainingAmount;
  
  /// 瓶種リストを取得
  List<BottleEntry> get bottleEntries => List.unmodifiable(_bottleEntries);
  
  /// 総本数を取得
  int get totalBottles {
    return _bottleEntries.fold(0, (sum, entry) => sum + entry.totalBottles);
  }
  
  /// 総容量を取得
  double get totalVolume {
    return _bottleEntries.fold(0.0, (sum, entry) => sum + entry.totalVolume);
  }
  
  /// 詰残を含む合計容量を取得
  double get totalVolumeWithRemaining {
    return totalVolume + (_remainingAmount * 1.8);
  }
  
  /// 純アルコール量を取得
  double get pureAlcoholAmount {
    return totalVolumeWithRemaining * _alcoholPercentage / 100;
  }
  
  /// エラーメッセージを取得
  String? get errorMessage => _errorMessage;
  
  /// エラーがあるかどうか
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  
  /// 更新モードかどうか
  bool get isUpdateMode => _isUpdateMode;
  
  /// 編集中の瓶詰め情報ID
  String? get currentBottlingInfoId => _currentBottlingInfo?.id;

  /// 新規作成モードに設定
  void setCreateMode() {
    _isUpdateMode = false;
    _currentBottlingInfo = null;
    _resetValues();
    notifyListeners();
  }

  /// 更新モードに設定
  void setUpdateMode(BottlingInfo info) {
    _isUpdateMode = true;
    _currentBottlingInfo = info;
    
    // 値を設定
    _date = info.date;
    _sakeName = info.sakeName;
    _alcoholPercentage = info.alcoholPercentage;
    _temperature = info.temperature;
    _remainingAmount = info.remainingAmount;
    
    // 瓶種リストをコピー
    _bottleEntries.clear();
    _bottleEntries.addAll(info.bottleEntries);
    
    notifyListeners();
  }

  /// 値をリセット
  void _resetValues() {
    _date = DateTime.now();
    _sakeName = '';
    _alcoholPercentage = 0.0;
    _temperature = null;
    _remainingAmount = 0.0;
    _bottleEntries.clear();
    _errorMessage = null;
  }

  /// 日付を設定
  void setDate(DateTime date) {
    _date = date;
    notifyListeners();
  }

  /// 酒名を設定
  void setSakeName(String sakeName) {
    _sakeName = sakeName;
    notifyListeners();
  }

  /// アルコール度数を設定
  void setAlcoholPercentage(double alcoholPercentage) {
    _alcoholPercentage = alcoholPercentage;
    notifyListeners();
  }

  /// 品温を設定
  void setTemperature(double? temperature) {
    _temperature = temperature;
    notifyListeners();
  }

  /// 詰残量を設定
  void setRemainingAmount(double remainingAmount) {
    _remainingAmount = remainingAmount;
    notifyListeners();
  }

  /// 瓶種エントリーを追加
  void addBottleEntry(BottleType bottleType, int cases, int bottles) {
    // 同じ瓶種がすでにある場合は更新
    final existingIndex = _bottleEntries.indexWhere(
      (entry) => entry.bottleType.name == bottleType.name && 
                 entry.bottleType.capacity == bottleType.capacity
    );
    
    if (existingIndex >= 0) {
      // 既存のエントリーを更新
      _bottleEntries[existingIndex] = BottleEntry(
        bottleType: bottleType,
        cases: cases,
        bottles: bottles,
      );
    } else {
      // 新しいエントリーを追加
      _bottleEntries.add(
        BottleEntry(
          bottleType: bottleType,
          cases: cases,
          bottles: bottles,
        ),
      );
    }
    
    notifyListeners();
  }

  /// 瓶種エントリーを削除
  void removeBottleEntry(int index) {
    if (index >= 0 && index < _bottleEntries.length) {
      _bottleEntries.removeAt(index);
      notifyListeners();
    }
  }

  /// 瓶詰め情報を保存
  Future<void> saveBottlingInfo() async {
    // バリデーション
    if (_sakeName.isEmpty) {
      _errorMessage = '酒名を入力してください';
      notifyListeners();
      return;
    }
    
    if (_alcoholPercentage <= 0) {
      _errorMessage = 'アルコール度数を入力してください';
      notifyListeners();
      return;
    }
    
    if (_bottleEntries.isEmpty) {
      _errorMessage = '少なくとも1つの瓶種を追加してください';
      notifyListeners();
      return;
    }

    try {
      await _bottlingManager.initialize();
      
      final now = DateTime.now();
      
      if (_isUpdateMode && _currentBottlingInfo != null) {
        // 更新モード
        final updatedInfo = _currentBottlingInfo!.copyWith(
          date: _date,
          sakeName: _sakeName,
          alcoholPercentage: _alcoholPercentage,
          temperature: _temperature,
          bottleEntries: List.from(_bottleEntries),
          remainingAmount: _remainingAmount,
        );
        
        await _bottlingManager.updateBottlingInfo(updatedInfo);
      } else {
        // 新規作成モード
        final newInfo = BottlingInfo(
          id: now.millisecondsSinceEpoch.toString(),
          date: _date,
          sakeName: _sakeName,
          alcoholPercentage: _alcoholPercentage,
          temperature: _temperature,
          bottleEntries: List.from(_bottleEntries),
          remainingAmount: _remainingAmount,
          createdAt: now,
        );
        
        await _bottlingManager.addBottlingInfo(newInfo);
      }
      
      // 値をリセット
      _resetValues();
      
      notifyListeners();
    } catch (e) {
      _errorMessage = '保存に失敗しました: $e';
      notifyListeners();
    }
  }
}