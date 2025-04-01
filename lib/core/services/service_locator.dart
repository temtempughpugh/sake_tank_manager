// lib/core/services/service_locator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/single_child_widget.dart';
import 'tank_data_service.dart';
import 'calculation_service.dart';
import 'storage_service.dart';
import '../../features/dilution/controllers/dilution_plan_manager.dart';
import '../../features/bottling/controllers/bottling_manager.dart';
import '../../features/brewing/controllers/brewing_record_service.dart';

/// サービスロケーター
/// アプリ全体で使用されるサービスのインスタンスを管理し、提供します
class ServiceLocator {
  /// アプリのサービスプロバイダーをセットアップ
  static Future<List<SingleChildWidget>> setupProviders() async {
    try {
      print('サービスの初期化を開始します...');
      
      // SharedPreferencesインスタンスを取得
      final sharedPreferences = await SharedPreferences.getInstance();
      print('SharedPreferences初期化完了');
      
      // StorageServiceの初期化
      final storageService = StorageService(sharedPreferences);
      print('StorageService初期化完了');
      
      // TankDataServiceの初期化 - 必ず完了を待つ
      print('TankDataService初期化開始');
      final tankDataService = TankDataService();
      // 重要: CSVデータの読み込みが完了するまで待機
      await tankDataService.initialize();
      if (!tankDataService.isInitialized) {
        throw Exception('TankDataServiceの初期化に失敗しました');
      }
      print('TankDataService初期化完了: ${tankDataService.allTanks.length}件のタンクデータをロード');
      
      // CalculationServiceの初期化
      final calculationService = CalculationService(tankDataService);
      print('CalculationService初期化完了');
      
      // DilutionPlanManagerの初期化
      print('DilutionPlanManager初期化開始');
      final dilutionPlanManager = DilutionPlanManager(storageService);
      await dilutionPlanManager.initialize();
      print('DilutionPlanManager初期化完了');
      
      // BottlingManagerの初期化
      print('BottlingManager初期化開始');
      final bottlingManager = BottlingManager(storageService);
      await bottlingManager.initialize();
      print('BottlingManager初期化完了');
      
      // BrewingRecordServiceの初期化
      print('BrewingRecordService初期化開始');
      final brewingRecordService = BrewingRecordService(
        storageService: storageService,
        bottlingManager: bottlingManager,
      );
      await brewingRecordService.initialize();
      print('BrewingRecordService初期化完了');
      
      print('すべてのサービスの初期化が正常に完了しました');
      
      // プロバイダーのリストを返す
      return [
        Provider<StorageService>.value(value: storageService),
        Provider<TankDataService>.value(value: tankDataService),
        Provider<CalculationService>.value(value: calculationService),
        Provider<DilutionPlanManager>.value(value: dilutionPlanManager),
        Provider<BottlingManager>.value(value: bottlingManager),
        Provider<BrewingRecordService>.value(value: brewingRecordService),
      ];
    } catch (e) {
      print('サービスの初期化中にエラーが発生しました: $e');
      throw e; // エラーを上位に伝播させる
    }
  }
}