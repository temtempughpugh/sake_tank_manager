import 'measurement_data.dart';

/// 近似値とその情報を表すモデルクラス
class ApproximationPair {
  /// 元となる測定データ
  final MeasurementData data;
  
  /// 計算値または検索値との差
  final double difference;
  
  /// 完全一致かどうか
  final bool isExactMatch;
  
  /// 一番近い値かどうか
  final bool isClosest;

  ApproximationPair({
    required this.data,
    required this.difference,
    this.isExactMatch = false,
    this.isClosest = false,
  });

  /// 差の絶対値（表示用）
  double get absoluteDifference => difference.abs();

  @override
  String toString() {
    return 'ApproximationPair(data: $data, difference: $difference, isExactMatch: $isExactMatch, isClosest: $isClosest)';
  }
}