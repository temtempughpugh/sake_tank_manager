import 'package:collection/collection.dart';
import 'tank_category.dart';
import 'measurement_data.dart';

/// タンク情報を表すモデルクラス
class Tank {
  /// タンク番号 (例: "No.16")
  final String number;
  
  /// タンクカテゴリ
  final TankCategory category;
  
  /// 検尺値と容量のペアのリスト
  final List<MeasurementData> measurements;

  Tank({
    required this.number,
    required this.category,
    required this.measurements,
  });

  /// タンクの最大容量を取得
  double get maxVolume {
    if (measurements.isEmpty) return 0.0;
    return measurements.map((m) => m.volume).max;
  }

  /// タンクの最小容量を取得
  double get minVolume {
    if (measurements.isEmpty) return 0.0;
    return measurements.map((m) => m.volume).min;
  }

  /// タンクの最大検尺値を取得
  double get maxDipstick {
    if (measurements.isEmpty) return 0.0;
    return measurements.map((m) => m.dipstick).max;
  }

  /// タンクの最小検尺値を取得
  double get minDipstick {
    if (measurements.isEmpty) return 0.0;
    return measurements.map((m) => m.dipstick).min;
  }

  /// 検尺から容量を求める
  /// - [dipstick]: 検尺値(mm)
  /// - 戻り値: 完全一致するデータがあればその容量、なければnull
  double? dipstickToVolume(double dipstick) {
    // 完全一致を検索
    final exactMatch = measurements.firstWhereOrNull((m) => m.dipstick == dipstick);
    return exactMatch?.volume;
  }

  /// 容量から検尺を求める
  /// - [volume]: 容量(L)
  /// - 戻り値: 完全一致するデータがあればその検尺、なければnull
  double? volumeToDipstick(double volume) {
    // 完全一致を検索
    final exactMatch = measurements.firstWhereOrNull((m) => m.volume == volume);
    return exactMatch?.dipstick;
  }

  /// 近似値検索 (検尺値から近い値を探す)
  /// - [dipstick]: 検尺値(mm)
  /// - [count]: 返す近似値の数
  /// - 戻り値: 近似値のリスト
  List<MeasurementData> findApproximateDipsticks(double dipstick, {int count = 5}) {
    // 検尺値でソート
    final sorted = List<MeasurementData>.from(measurements)
      ..sort((a, b) => (a.dipstick - dipstick).abs().compareTo((b.dipstick - dipstick).abs()));
    
    // 指定した数だけ返す（最大count個）
    return sorted.take(count).toList();
  }

  /// 近似値検索 (容量から近い値を探す)
  /// - [volume]: 容量(L)
  /// - [count]: 返す近似値の数
  /// - 戻り値: 近似値のリスト
  List<MeasurementData> findApproximateVolumes(double volume, {int count = 5}) {
    // 容量でソート
    final sorted = List<MeasurementData>.from(measurements)
      ..sort((a, b) => (a.volume - volume).abs().compareTo((b.volume - volume).abs()));
    
    // 指定した数だけ返す（最大count個）
    return sorted.take(count).toList();
  }
}