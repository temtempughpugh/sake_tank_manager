/// 検尺値と容量のデータペアを表すモデルクラス
class MeasurementData {
  /// 検尺値（タンク上部からの距離、mm単位）
  final double dipstick;
  
  /// 容量値（L単位）
  final double volume;

  /// コンストラクタ
  MeasurementData({
    required this.dipstick,
    required this.volume,
  });

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'dipstick': dipstick,
      'volume': volume,
    };
  }

  /// Map形式から復元
  factory MeasurementData.fromMap(Map<String, dynamic> map) {
    return MeasurementData(
      dipstick: map['dipstick'],
      volume: map['volume'],
    );
  }

  @override
  String toString() => 'MeasurementData(dipstick: $dipstick, volume: $volume)';
}