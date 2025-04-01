// lib/core/services/controller_factory.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/tank_reference/controllers/tank_reference_controller.dart';
import '../../features/dilution/controllers/dilution_controller.dart';
import '../../features/bottling/controllers/bottling_controller.dart';
import '../../features/brewing/controllers/brewing_record_controller.dart';
import '../../features/brewing/controllers/brewing_timeline_controller.dart';

import 'tank_data_service.dart';
import 'calculation_service.dart';
import 'storage_service.dart';
import '../../features/dilution/controllers/dilution_plan_manager.dart';
import '../../features/bottling/controllers/bottling_manager.dart';
import '../../features/brewing/controllers/brewing_record_service.dart';

/// コントローラーのファクトリークラス
class ControllerFactory {
  /// TankReferenceControllerを作成
  static TankReferenceController createTankReferenceController(BuildContext context) {
    final tankDataService = Provider.of<TankDataService>(context, listen: false);
    final calculationService = Provider.of<CalculationService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    return TankReferenceController(
      tankDataService: tankDataService,
      calculationService: calculationService,
      storageService: storageService,
    );
  }

  /// DilutionControllerを作成
  static DilutionController createDilutionController(BuildContext context) {
    final tankDataService = Provider.of<TankDataService>(context, listen: false);
    final calculationService = Provider.of<CalculationService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final planManager = Provider.of<DilutionPlanManager>(context, listen: false);
    
    return DilutionController(
      tankDataService: tankDataService,
      calculationService: calculationService,
      storageService: storageService,
      planManager: planManager,
    );
  }

  /// BottlingControllerを作成
  static BottlingController createBottlingController(BuildContext context) {
    final bottlingManager = Provider.of<BottlingManager>(context, listen: false);
    
    return BottlingController(
      bottlingManager: bottlingManager,
    );
  }

  /// BrewingRecordControllerを作成
  static BrewingRecordController createBrewingRecordController(BuildContext context) {
    final recordService = Provider.of<BrewingRecordService>(context, listen: false);
    final tankDataService = Provider.of<TankDataService>(context, listen: false);
    final calculationService = Provider.of<CalculationService>(context, listen: false);
    
    return BrewingRecordController(
      recordService: recordService,
      tankDataService: tankDataService,
      calculationService: calculationService,
    );
  }

  /// BrewingTimelineControllerを作成
  static BrewingTimelineController createBrewingTimelineController(BuildContext context) {
    final recordService = Provider.of<BrewingRecordService>(context, listen: false);
    
    return BrewingTimelineController(
      recordService: recordService,
    );
  }
}