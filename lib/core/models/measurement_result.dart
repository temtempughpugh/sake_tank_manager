/// 測定・計算結果を表すモデルクラス
class MeasurementResult {
  /// 検尺値 (mm)
  final double dipstick;
  
  /// 容量 (L)
  final double volume;
  
  /// エラーメッセージ (エラーがある場合)
  final String? errorMessage;
  
  /// 完全一致しているかどうか
  final bool isExactMatch;

  /// コンストラクタ
  MeasurementResult({
    required this.dipstick,
    required this.volume,
    this.errorMessage,
    this.isExactMatch = false,
  });

  /// エラーがあるかどうか
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// エラー結果を作成するファクトリメソッド
  factory MeasurementResult.error(String message) {
    return MeasurementResult(
      dipstick: 0,
      volume: 0,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    return 'MeasurementResult(dipstick: $dipstick, volume: $volume, isExactMatch: $isExactMatch${hasError ? ', error: $errorMessage' : ''})';
  }
}