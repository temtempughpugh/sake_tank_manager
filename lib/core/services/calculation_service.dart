// lib/core/services/calculation_service.dart
import '../models/tank.dart';
import '../models/measurement_data.dart';
import '../models/measurement_result.dart';
import '../models/approximation_pair.dart';
import '../models/dilution_result.dart';
import 'tank_data_service.dart';

/// 計算サービスクラス
/// 検尺・容量変換、アルコール計算、割水計算などを提供
class CalculationService {
  /// タンクデータサービス
  final TankDataService _tankDataService;

  /// コンストラクタ - TankDataServiceを注入
  CalculationService(this._tankDataService);

  // ========================
  // タンク計算
  // ========================

  /// 検尺値から容量を計算
  /// - [tankNumber]: タンク番号
  /// - [dipstick]: 検尺値(mm)
  /// - 戻り値: 測定結果
  MeasurementResult dipstickToVolume(String tankNumber, double dipstick) {
    // タンクの存在チェック
    final tank = _tankDataService.getTank(tankNumber);
    if (tank == null) {
      return MeasurementResult.error('タンク番号 $tankNumber が見つかりません');
    }

    try {
      // 範囲チェック
      if (dipstick < tank.minDipstick) {
        return MeasurementResult.error('検尺値が下限 (${tank.minDipstick.toStringAsFixed(0)}mm) より小さいです');
      }
      if (dipstick > tank.maxDipstick) {
        return MeasurementResult.error('検尺値が上限 (${tank.maxDipstick.toStringAsFixed(0)}mm) より大きいです');
      }

      // データの一致確認
      final volume = tank.dipstickToVolume(dipstick);
      
      // 完全一致
      if (volume != null) {
        return MeasurementResult(
          dipstick: dipstick,
          volume: volume,
          isExactMatch: true,
        );
      } 
      
      // 完全一致しない場合
      return MeasurementResult(
        dipstick: dipstick,
        volume: 0, // 仮の値（近似値選択UI表示のために必要）
        isExactMatch: false,
      );
    } catch (e) {
      return MeasurementResult.error('計算エラー: $e');
    }
  }

  /// 容量から検尺値を計算
  /// - [tankNumber]: タンク番号
  /// - [volume]: 容量(L)
  /// - 戻り値: 測定結果
  MeasurementResult volumeToDipstick(String tankNumber, double volume) {
    // タンクの存在チェック
    final tank = _tankDataService.getTank(tankNumber);
    if (tank == null) {
      return MeasurementResult.error('タンク番号 $tankNumber が見つかりません');
    }

    try {
      // 範囲チェック
      if (volume < tank.minVolume) {
        return MeasurementResult.error('容量が下限 (${tank.minVolume.toStringAsFixed(1)}L) より小さいです');
      }
      if (volume > tank.maxVolume) {
        return MeasurementResult.error('容量が上限 (${tank.maxVolume.toStringAsFixed(1)}L) より大きいです');
      }

      // データの一致確認
      final dipstick = tank.volumeToDipstick(volume);
      
      // 完全一致
      if (dipstick != null) {
        return MeasurementResult(
          dipstick: dipstick,
          volume: volume,
          isExactMatch: true,
        );
      }
      
      // 完全一致しない場合
      return MeasurementResult(
        dipstick: 0, // 仮の値（近似値選択UI表示のために必要）
        volume: volume,
        isExactMatch: false,
      );
    } catch (e) {
      return MeasurementResult.error('計算エラー: $e');
    }
  }

  /// 検尺値の近似値を検索
  /// - [tankNumber]: タンク番号
  /// - [dipstick]: 検尺値(mm)
  /// - [count]: 返す近似値の数
  /// - 戻り値: 近似値ペアのリスト
  List<ApproximationPair> findApproximateDipsticks(
    String tankNumber, 
    double dipstick, 
    {int count = 5}
  ) {
    // タンクの存在チェック
    final tank = _tankDataService.getTank(tankNumber);
    if (tank == null) {
      return [];
    }

    // 検尺値でソート
    final measurements = tank.measurements.toList()
      ..sort((a, b) => (a.dipstick - dipstick).abs().compareTo((b.dipstick - dipstick).abs()));

    // 近似値リストの作成
    final result = <ApproximationPair>[];
    bool hasExactMatch = false;

    for (int i = 0; i < measurements.length && i < count; i++) {
      final data = measurements[i];
      final diff = data.dipstick - dipstick;
      final isExactMatch = diff == 0;
      
      if (isExactMatch) {
        hasExactMatch = true;
      }

      result.add(ApproximationPair(
        data: data,
        difference: diff,
        isExactMatch: isExactMatch,
        isClosest: i == 0 && !isExactMatch,
      ));
    }

    return result;
  }

  /// 容量の近似値を検索
  /// - [tankNumber]: タンク番号
  /// - [volume]: 容量(L)
  /// - [count]: 返す近似値の数
  /// - 戻り値: 近似値ペアのリスト
  List<ApproximationPair> findApproximateVolumes(
    String tankNumber, 
    double volume, 
    {int count = 5}
  ) {
    // タンクの存在チェック
    final tank = _tankDataService.getTank(tankNumber);
    if (tank == null) {
      return [];
    }

    // 容量でソート
    final measurements = tank.measurements.toList()
      ..sort((a, b) => (a.volume - volume).abs().compareTo((b.volume - volume).abs()));

    // 近似値リストの作成
    final result = <ApproximationPair>[];
    bool hasExactMatch = false;

    for (int i = 0; i < measurements.length && i < count; i++) {
      final data = measurements[i];
      final diff = data.volume - volume;
      final isExactMatch = diff == 0;
      
      if (isExactMatch) {
        hasExactMatch = true;
      }

      result.add(ApproximationPair(
        data: data,
        difference: diff,
        isExactMatch: isExactMatch,
        isClosest: i == 0 && !isExactMatch,
      ));
    }

    return result;
  }

  // ========================
  // アルコール計算
  // ========================

  /// 純アルコール量を計算
  /// - [volume]: 容量(L)
  /// - [alcoholPercentage]: アルコール度数(%)
  /// - 戻り値: 純アルコール量(L)
  double calculatePureAlcohol(double volume, double alcoholPercentage) {
    return volume * alcoholPercentage / 100;
  }

  /// 割水後の最終容量を計算
  /// - [initialVolume]: 初期容量(L)
  /// - [initialAlcohol]: 初期アルコール度数(%)
  /// - [targetAlcohol]: 目標アルコール度数(%)
  /// - 戻り値: 最終容量(L)
  double calculateFinalVolume(
    double initialVolume,
    double initialAlcohol,
    double targetAlcohol,
  ) {
    if (targetAlcohol <= 0) {
      throw ArgumentError('目標アルコール度数は0より大きい値にしてください');
    }
    
    if (initialAlcohol <= targetAlcohol) {
      throw ArgumentError('目標アルコール度数は初期アルコール度数より小さい値にしてください');
    }
    
    return initialVolume * (initialAlcohol / targetAlcohol);
  }

  /// 割水量を計算
  /// - [initialVolume]: 初期容量(L)
  /// - [initialAlcohol]: 初期アルコール度数(%)
  /// - [targetAlcohol]: 目標アルコール度数(%)
  /// - 戻り値: 追加する水量(L)
  double calculateWaterAmount(
    double initialVolume,
    double initialAlcohol,
    double targetAlcohol,
  ) {
    final finalVolume = calculateFinalVolume(
      initialVolume,
      initialAlcohol,
      targetAlcohol,
    );
    
    return finalVolume - initialVolume;
  }

  /// 最終アルコール度数を計算
  /// - [initialVolume]: 初期容量(L)
  /// - [initialAlcohol]: 初期アルコール度数(%)
  /// - [finalVolume]: 最終容量(L)
  /// - 戻り値: 最終アルコール度数(%)
  double calculateFinalAlcohol(
    double initialVolume,
    double initialAlcohol,
    double finalVolume,
  ) {
    if (finalVolume <= 0) {
      throw ArgumentError('最終容量は0より大きい値にしてください');
    }
    
    return (initialVolume * initialAlcohol) / finalVolume;
  }

  // 逆引き: 割水後容量から蔵出し容量を計算
  double calculateInitialVolume(
    double finalVolume,
    double initialAlcoholPercentage,  // 元酒アルコール度数
    double targetAlcoholPercentage    // 目標アルコール度数
  ) {
    // アルコール量保存の原理を逆に適用
    return finalVolume * (targetAlcoholPercentage / initialAlcoholPercentage);
  }

  // ========================
  // 複合計算 (割水計算)
  // ========================

  /// 割水計算を実行
  /// - [tankNumber]: タンク番号
  /// - [initialValue]: 初期値（検尺または容量）
  /// - [isUsingDipstick]: 初期値が検尺かどうか（falseなら容量）
  /// - [initialAlcohol]: 初期アルコール度数(%)
  /// - [targetAlcohol]: 目標アルコール度数(%)
  /// - [sakeName]: 酒名（オプション）
  /// - [personInCharge]: 担当者名（オプション）
  /// - 戻り値: 割水計算結果
  DilutionResult calculateDilution({
    required String tankNumber,
    required double initialValue,
    required bool isUsingDipstick,
    required double initialAlcohol,
    required double targetAlcohol,
    String? sakeName,
    String? personInCharge,
  }) {
    // タンクの存在チェック
    final tank = _tankDataService.getTank(tankNumber);
    if (tank == null) {
      return DilutionResult.error(tankNumber, 'タンク番号 $tankNumber が見つかりません');
    }

    try {
      // バリデーション
      if (initialAlcohol <= 0) {
        return DilutionResult.error(tankNumber, '初期アルコール度数は0より大きい値にしてください');
      }
      
      if (targetAlcohol <= 0) {
        return DilutionResult.error(tankNumber, '目標アルコール度数は0より大きい値にしてください');
      }
      
      if (initialAlcohol <= targetAlcohol) {
        return DilutionResult.error(
          tankNumber, 
          '目標アルコール度数(${targetAlcohol}%)は初期アルコール度数(${initialAlcohol}%)より小さい値にしてください'
        );
      }

      // 初期検尺・容量の変換
      double initialDipstick;
      double initialVolume;
      
      if (isUsingDipstick) {
        initialDipstick = initialValue;
        final volumeResult = dipstickToVolume(tankNumber, initialDipstick);
        
        if (volumeResult.hasError) {
          return DilutionResult.error(tankNumber, volumeResult.errorMessage!);
        }
        
        initialVolume = volumeResult.volume;
      } else {
        initialVolume = initialValue;
        // 蔵出し検尺値の計算 - ここを詳細にデバッグ・修正
        final dipstickResult = volumeToDipstick(tankNumber, initialVolume);
        print('DEBUG: 逆引き計算 - 蔵出し容量=$initialVolume L');
        print('DEBUG: volumeToDipstick 結果=${dipstickResult.dipstick} mm (エラー=${dipstickResult.hasError})');

        if (dipstickResult.hasError) {
          return DilutionResult.error(tankNumber, dipstickResult.errorMessage!);
        }
        initialDipstick = dipstickResult.dipstick;
      }

      // 割水計算
      final waterAmount = calculateWaterAmount(initialVolume, initialAlcohol, targetAlcohol);
      final finalVolume = initialVolume + waterAmount;
      
      // 最大容量チェック
      if (finalVolume > tank.maxVolume) {
        return DilutionResult.error(
          tankNumber, 
          '最終容量(${finalVolume.toStringAsFixed(1)}L)がタンクの最大容量(${tank.maxVolume.toStringAsFixed(1)}L)を超えています'
        );
      }
      
      // 最終検尺の計算
      final dipstickResult = volumeToDipstick(tankNumber, finalVolume);
      if (dipstickResult.hasError) {
        return DilutionResult.error(tankNumber, dipstickResult.errorMessage!);
      }
      
      final finalDipstick = dipstickResult.dipstick;
      
      // 最終アルコール度数の再計算（丸め誤差防止）
      final finalAlcohol = calculateFinalAlcohol(initialVolume, initialAlcohol, finalVolume);

      return DilutionResult(
        tankNumber: tankNumber,
        initialVolume: initialVolume,
        initialDipstick: initialDipstick,
        initialAlcoholPercentage: initialAlcohol,
        targetAlcoholPercentage: targetAlcohol,
        waterAmount: waterAmount,
        finalVolume: finalVolume,
        finalDipstick: finalDipstick,
        finalAlcoholPercentage: finalAlcohol,
        sakeName: sakeName,
        personInCharge: personInCharge,
      );
    } catch (e) {
      return DilutionResult.error(tankNumber, '計算エラー: $e');
    }
  }

  /// 逆引き割水計算を実行
  DilutionResult calculateReverseDilution({
    required String tankNumber,
    required double finalValue,  // 割水後の値（検尺または容量）
    required bool isUsingDipstick,
    required double initialAlcoholPercentage,
    required double targetAlcoholPercentage,
    String? sakeName,
    String? personInCharge,
  }) {
    // タンク情報取得とバリデーション
    final tank = _tankDataService.getTank(tankNumber);
    if (tank == null) {
      return DilutionResult.error(tankNumber, 'タンク番号 $tankNumber が見つかりません');
    }
    
    try {
      // アルコール度数のバリデーション
      if (initialAlcoholPercentage <= targetAlcoholPercentage) {
        return DilutionResult.error(
          tankNumber, 
          '元酒アルコール度数(${initialAlcoholPercentage}%)は目標アルコール度数(${targetAlcoholPercentage}%)より大きい値にしてください'
        );
      }
      
      // 割水後の検尺/容量変換
      double finalDipstick;
      double finalVolume;
      
      if (isUsingDipstick) {
        // 検尺から容量を計算
        finalDipstick = finalValue;
        final volumeResult = dipstickToVolume(tankNumber, finalDipstick);
        if (volumeResult.hasError) {
          return DilutionResult.error(tankNumber, volumeResult.errorMessage!);
        }
        finalVolume = volumeResult.volume;
      } else {
        // 容量から検尺を計算
        finalVolume = finalValue;
        final dipstickResult = volumeToDipstick(tankNumber, finalVolume);
        if (dipstickResult.hasError) {
          return DilutionResult.error(tankNumber, dipstickResult.errorMessage!);
        }
        finalDipstick = dipstickResult.dipstick;
      }
      
      // 蔵出し容量の計算
      final initialVolume = calculateInitialVolume(
        finalVolume, 
        initialAlcoholPercentage, 
        targetAlcoholPercentage
      );
      
      // 蔵出し容量のバリデーション
      if (initialVolume < tank.minVolume) {
        return DilutionResult.error(
          tankNumber, 
          '計算された蔵出し容量(${initialVolume.toStringAsFixed(1)}L)がタンクの最小容量(${tank.minVolume.toStringAsFixed(1)}L)未満です'
        );
      }
      
      // 蔵出し検尺値の計算
      final dipstickResult = volumeToDipstick(tankNumber, initialVolume);
      if (dipstickResult.hasError) {
        return DilutionResult.error(tankNumber, dipstickResult.errorMessage!);
      }
      
      final initialDipstick = dipstickResult.dipstick;
      
      // 追加水量
      final waterAmount = finalVolume - initialVolume;
      print('DEBUG: 設定される蔵出し検尺値=$initialDipstick mm');
      
      // DilutionResultオブジェクトを返す
      return DilutionResult(
        tankNumber: tankNumber,
        initialVolume: initialVolume,
        initialDipstick: initialDipstick,
        initialAlcoholPercentage: initialAlcoholPercentage,
        targetAlcoholPercentage: targetAlcoholPercentage,
        waterAmount: waterAmount,
        finalVolume: finalVolume,
        finalDipstick: finalDipstick,
        finalAlcoholPercentage: targetAlcoholPercentage,
      );
    } catch (e) {
      return DilutionResult.error(tankNumber, '計算エラー: $e');
    }
  }
}