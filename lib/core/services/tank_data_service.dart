// lib/core/services/tank_data_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/tank.dart';
import '../models/tank_category.dart';
import '../models/measurement_data.dart';

/// タンクデータを管理するサービスクラス
class TankDataService {
  /// 読み込み済みのタンクデータ
  final Map<String, Tank> _tanks = {};

  /// タンクデータの読み込み完了状態
  bool _isInitialized = false;

  /// コンストラクタ
  TankDataService();

  /// タンクデータの初期化
  /// - CSVからタンクデータを読み込み
  /// - 戻り値: Future<void>（非同期処理）
  Future<void> initialize() async {
    if (_isInitialized) return; // 既に初期化済みの場合は何もしない

    try {
      // CSVファイルの読み込み
      final String csvData = await rootBundle.loadString('assets/tank_quick_reference.csv');
      print('CSV読み込み完了: ${csvData.length}バイト');
      
      // CSVデータのパース
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);
      print('CSVデータ行数: ${rows.length}');
      
      // ヘッダー行をスキップ
      if (rows.isNotEmpty) {
        rows.removeAt(0); // 最初の行はヘッダー
      }
      
      // 3列ごとにタンクデータを解析
      Map<String, List<MeasurementData>> tankMeasurements = {};
      
      for (var row in rows) {
        // 3列ごとに1つのタンクデータとして処理
        for (int i = 0; i < row.length; i += 3) {
          if (i + 2 < row.length) {
            final String tankNumber = row[i].toString();
            if (tankNumber.isEmpty) continue;
            
            final double volume = double.tryParse(row[i + 1].toString()) ?? 0;
            final double dipstick = double.tryParse(row[i + 2].toString()) ?? 0;
            
            // タンク番号ごとにデータをグループ化
            if (!tankMeasurements.containsKey(tankNumber)) {
              tankMeasurements[tankNumber] = [];
            }
            
            tankMeasurements[tankNumber]!.add(
              MeasurementData(
                volume: volume,
                dipstick: dipstick,
              ),
            );
          }
        }
      }
      
      print('解析済みタンク数: ${tankMeasurements.keys.length}');
      
      // タンクオブジェクトの作成
      tankMeasurements.forEach((tankNumber, measurements) {
        final TankCategory category = TankCategory.fromTankNumber(tankNumber);
        _tanks[tankNumber] = Tank(
          number: tankNumber,
          category: category,
          measurements: measurements,
        );
        print('タンク $tankNumber: ${measurements.length}件のデータを登録');
      });
      
      _isInitialized = true;
    } catch (e) {
      print('タンクデータの読み込みエラー: $e');
      rethrow;
    }
  }

  /// 初期化されているかをチェック
  bool get isInitialized => _isInitialized;

  /// 全タンクリストを取得
  List<Tank> get allTanks => _tanks.values.toList();

  /// カテゴリでソートされた全タンクリストを取得
  List<Tank> get sortedTanks {
    final sorted = _tanks.values.toList()
      ..sort((a, b) => a.category.priorityOrder.compareTo(b.category.priorityOrder));
    return sorted;
  }

  /// カテゴリ別のタンクリストを取得
  Map<TankCategory, List<Tank>> get tanksByCategory {
    final result = <TankCategory, List<Tank>>{};
    
    for (final category in TankCategory.values) {
      result[category] = _tanks.values
          .where((tank) => tank.category == category)
          .toList();
    }
    
    return result;
  }

  /// タンク番号からタンクを取得
  /// - [tankNumber]: タンク番号
  /// - 戻り値: タンク（見つからない場合はnull）
  Tank? getTank(String tankNumber) {
    return _tanks[tankNumber];
  }

  /// 蔵出しタンクを取得
  List<Tank> get kuradashiTanks {
    return _tanks.values
        .where((tank) => tank.category == TankCategory.kuradashi)
        .toList();
  }

  /// タンクの有無をチェック
  bool hasTank(String tankNumber) {
    return _tanks.containsKey(tankNumber);
  }
}