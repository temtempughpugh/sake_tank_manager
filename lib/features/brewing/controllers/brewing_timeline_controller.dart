import 'package:flutter/material.dart';
import '../models/brewing_record.dart';
import '../models/dilution_stage.dart';
import '../models/movement_stage.dart';
import '../models/bottling_info_update.dart';
import '../../bottling/models/bottling_info.dart';
import 'brewing_record_service.dart';

/// タイムラインデータを表すクラス
class TimelineData {
  /// 瓶詰め情報
  final BottlingInfo bottlingInfo;
  
  /// 記帳記録
  final BrewingRecord record;
  
  /// 欠減データのリスト（計算済み）
  final List<ShortageData> shortages;

  /// コンストラクタ
  TimelineData({
    required this.bottlingInfo,
    required this.record,
    required this.shortages,
  });
}

/// 欠減データを表すクラス
class ShortageData {
  /// 欠減の種類
  final String type;
  
  /// 欠減量（リットル）
  final double amount;
  
  /// 欠減率（%）
  final double percentage;
  
  /// 開始数量（リットル）
  final double startVolume;
  
  /// 終了数量（リットル）
  final double endVolume;
  
  /// 開始工程の説明
  final String startDescription;
  
  /// 終了工程の説明
  final String endDescription;

  /// コンストラクタ
  ShortageData({
    required this.type,
    required this.amount,
    required this.percentage,
    required this.startVolume,
    required this.endVolume,
    required this.startDescription,
    required this.endDescription,
  });
}

/// 記帳タイムラインのコントローラークラス
class BrewingTimelineController extends ChangeNotifier {
  /// 記帳サービス
  final BrewingRecordService _recordService = BrewingRecordService();
  
  /// 瓶詰め情報ID
  String? _bottlingInfoId;
  
  /// 瓶詰め情報
  BottlingInfo? _bottlingInfo;
  
  /// 記帳記録
  BrewingRecord? _record;
  
  /// タイムラインデータ
  TimelineData? _timelineData;
  
  /// 読み込み中フラグ
  bool _isLoading = false;
  
  /// エラーメッセージ
  String? _errorMessage;

  /// 瓶詰め情報を取得
  BottlingInfo? get bottlingInfo => _bottlingInfo;
  
  /// 記帳記録を取得
  BrewingRecord? get record => _record;
  
  /// タイムラインデータを取得
  TimelineData? get timelineData => _timelineData;
  
  /// 読み込み中かどうかを取得
  bool get isLoading => _isLoading;
  
  /// エラーメッセージを取得
  String? get errorMessage => _errorMessage;

  /// 初期化
  Future<void> initialize(String bottlingInfoId) async {
    _bottlingInfoId = bottlingInfoId;
    await loadTimelineData();
  }

  /// タイムラインデータを読み込む
  Future<void> loadTimelineData() async {
    if (_bottlingInfoId == null) return;
    
    _setLoading(true);
    
    try {
      // 記帳サービスの初期化
      await _recordService.initialize();
      
      // 瓶詰め情報の取得
      final bottlingInfo = await _recordService.getBottlingInfo(_bottlingInfoId!);
      if (bottlingInfo == null) {
        _setError('瓶詰め情報が見つかりません: $_bottlingInfoId');
        return;
      }
      
      // 記帳記録の取得
      final records = await _recordService.getRecordsByBottlingInfoId(_bottlingInfoId!);
      if (records.isEmpty) {
        _setError('記帳記録が見つかりません');
        return;
      }
      
      // 最新の記帳記録を使用
      final latestRecord = records.first;
      
      // 欠減データの計算
      final shortages = _calculateShortages(latestRecord, bottlingInfo);
      
      // タイムラインデータの作成
      _bottlingInfo = bottlingInfo;
      _record = latestRecord;
      _timelineData = TimelineData(
        bottlingInfo: bottlingInfo,
        record: latestRecord,
        shortages: shortages,
      );
      
      _clearError();
      _setLoading(false);
    } catch (e) {
      _setError('タイムラインデータの読み込みに失敗しました: $e');
    }
  }

  /// 欠減データを計算
  List<ShortageData> _calculateShortages(BrewingRecord record, BottlingInfo bottlingInfo) {
    final List<ShortageData> shortages = [];
    
    final dilutionStage = record.dilutionStage;
    
    if (dilutionStage != null) {
      // 瓶詰め欠減（割水後→瓶詰め）
      final bottlingShortage = ShortageData(
        type: '瓶詰め欠減',
        amount: dilutionStage.shortageDilution,
        percentage: dilutionStage.shortageDilutionPercentage,
        startVolume: dilutionStage.finalVolume,
        endVolume: bottlingInfo.totalVolumeWithRemaining,
        startDescription: '割水後',
        endDescription: '瓶詰め時',
      );
      shortages.add(bottlingShortage);
      
      // 蔵出し欠減（蔵出し→割水前）
      if (dilutionStage.initialVolume < dilutionStage.initialVolume) {
        final extractionShortage = ShortageData(
          type: '蔵出し欠減',
          amount: dilutionStage.initialVolume - dilutionStage.initialVolume,
          percentage: ((dilutionStage.initialVolume - dilutionStage.initialVolume) / dilutionStage.initialVolume) * 100,
          startVolume: dilutionStage.initialVolume,
          endVolume: dilutionStage.initialVolume,
          startDescription: '蔵出し',
          endDescription: '割水前',
        );
        shortages.add(extractionShortage);
      }
    }
    
    // タンク移動の欠減を追加
    if (record.movementStages.isNotEmpty) {
      for (final stage in record.movementStages) {
        // 移動欠減を追加
        if (stage.shortageMovement != 0) {
          final movementShortage = ShortageData(
            type: '${stage.processName ?? "タンク移動"}欠減',
            amount: stage.shortageMovement,
            percentage: stage.shortageMovementPercentage,
            startVolume: stage.movementVolume,
            endVolume: stage.movementVolume - stage.shortageMovement,
            startDescription: '移動量',
            endDescription: '到着量',
          );
          shortages.add(movementShortage);
        }
      }
    }
    
    return shortages;
  }

  /// 読み込み中状態を設定
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

  /// エラーをクリア
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}