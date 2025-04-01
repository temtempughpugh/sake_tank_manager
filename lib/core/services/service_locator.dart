// lib/core/services/service_locator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // SharedPreferencesインスタンスを取得
    final sharedPreferences = await SharedPreferences.getInstance();
    
    // StorageServiceの初期化
    final storageService = StorageService(sharedPreferences);
    
    // TankDataServiceの初期化
    final tankDataService = TankDataService();
    await tankDataService.initialize();
    
    // CalculationServiceの初期化
    final calculationService = CalculationService(tankDataService);
    
    // DilutionPlanManagerの初期化
    final dilutionPlanManager = DilutionPlanManager(storageService);
    await dilutionPlanManager.initialize();
    
    // BottlingManagerの初期化
    final bottlingManager = BottlingManager(storageService);
    await bottlingManager.initialize();
    
    // BrewingRecordServiceの初期化
    final brewingRecordService = BrewingRecordService(
      storageService,
      bottlingManager,
    );
    await brewingRecordService.initialize();
    
    // プロバイダーのリストを返す
    return [
      Provider<StorageService>.value(value: storageService),
      Provider<TankDataService>.value(value: tankDataService),
      Provider<CalculationService>.value(value: calculationService),
      Provider<DilutionPlanManager>.value(value: dilutionPlanManager),
      Provider<BottlingManager>.value(value: bottlingManager),
      Provider<BrewingRecordService>.value(value: brewingRecordService),
    ];
  }
}