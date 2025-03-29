/// 割水工程の記録を表すモデルクラス
class DilutionStage {
  /// タンク番号
  final String tankNumber;
  
  /// 蔵出し容量 (L)
  final double initialVolume;
  
  /// 蔵出し検尺値 (mm)
  final double initialDipstick;
  
  /// 割水前アルコール度数 (%)
  final double initialAlcoholPercentage;
  
  /// 割水量 (L)
  final double dilutionWaterAmount;
  
  /// 割水後容量 (L)
  final double finalVolume;
  
  /// 割水後検尺値 (mm)
  final double finalDipstick;
  
  /// 割水後アルコール度数 (%)
  final double finalAlcoholPercentage;
  
  /// 瓶詰め総量 (L) - 瓶詰め情報から取得
  final double bottlingTotalVolume;
  
  /// 欠減量 (L) - 割水後容量と瓶詰め総量の差
  final double shortageDilution;
  
  /// 欠減率 (%) - 欠減量 / 割水後容量 * 100
  final double shortageDilutionPercentage;

  /// コンストラクタ
  DilutionStage({
    required this.tankNumber,
    required this.initialVolume,
    required this.initialDipstick,
    required this.initialAlcoholPercentage,
    required this.dilutionWaterAmount,
    required this.finalVolume,
    required this.finalDipstick,
    required this.finalAlcoholPercentage,
    required this.bottlingTotalVolume,
    required this.shortageDilution,
    required this.shortageDilutionPercentage,
  });

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'tankNumber': tankNumber,
      'initialVolume': initialVolume,
      'initialDipstick': initialDipstick,
      'initialAlcoholPercentage': initialAlcoholPercentage,
      'dilutionWaterAmount': dilutionWaterAmount,
      'finalVolume': finalVolume,
      'finalDipstick': finalDipstick,
      'finalAlcoholPercentage': finalAlcoholPercentage,
      'bottlingTotalVolume': bottlingTotalVolume,
      'shortageDilution': shortageDilution,
      'shortageDilutionPercentage': shortageDilutionPercentage,
    };
  }

  /// Map形式から復元
  factory DilutionStage.fromMap(Map<String, dynamic> map) {
    return DilutionStage(
      tankNumber: map['tankNumber'],
      initialVolume: map['initialVolume'],
      initialDipstick: map['initialDipstick'],
      initialAlcoholPercentage: map['initialAlcoholPercentage'],
      dilutionWaterAmount: map['dilutionWaterAmount'],
      finalVolume: map['finalVolume'],
      finalDipstick: map['finalDipstick'],
      finalAlcoholPercentage: map['finalAlcoholPercentage'],
      bottlingTotalVolume: map['bottlingTotalVolume'],
      shortageDilution: map['shortageDilution'],
      shortageDilutionPercentage: map['shortageDilutionPercentage'],
    );
  }

  /// コピーして新しいインスタンスを作成
  DilutionStage copyWith({
    String? tankNumber,
    double? initialVolume,
    double? initialDipstick,
    double? initialAlcoholPercentage,
    double? dilutionWaterAmount,
    double? finalVolume,
    double? finalDipstick,
    double? finalAlcoholPercentage,
    double? bottlingTotalVolume,
    double? shortageDilution,
    double? shortageDilutionPercentage,
  }) {
    return DilutionStage(
      tankNumber: tankNumber ?? this.tankNumber,
      initialVolume: initialVolume ?? this.initialVolume,
      initialDipstick: initialDipstick ?? this.initialDipstick,
      initialAlcoholPercentage: initialAlcoholPercentage ?? this.initialAlcoholPercentage,
      dilutionWaterAmount: dilutionWaterAmount ?? this.dilutionWaterAmount,
      finalVolume: finalVolume ?? this.finalVolume,
      finalDipstick: finalDipstick ?? this.finalDipstick,
      finalAlcoholPercentage: finalAlcoholPercentage ?? this.finalAlcoholPercentage,
      bottlingTotalVolume: bottlingTotalVolume ?? this.bottlingTotalVolume,
      shortageDilution: shortageDilution ?? this.shortageDilution,
      shortageDilutionPercentage: shortageDilutionPercentage ?? this.shortageDilutionPercentage,
    );
  }

  @override
  String toString() {
    return 'DilutionStage(tankNumber: $tankNumber, initialVolume: $initialVolume, initialDipstick: $initialDipstick, initialAlcoholPercentage: $initialAlcoholPercentage, dilutionWaterAmount: $dilutionWaterAmount, finalVolume: $finalVolume, finalDipstick: $finalDipstick, finalAlcoholPercentage: $finalAlcoholPercentage, bottlingTotalVolume: $bottlingTotalVolume, shortageDilution: $shortageDilution, shortageDilutionPercentage: $shortageDilutionPercentage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DilutionStage &&
      other.tankNumber == tankNumber &&
      other.initialVolume == initialVolume &&
      other.initialDipstick == initialDipstick &&
      other.initialAlcoholPercentage == initialAlcoholPercentage &&
      other.dilutionWaterAmount == dilutionWaterAmount &&
      other.finalVolume == finalVolume &&
      other.finalDipstick == finalDipstick &&
      other.finalAlcoholPercentage == finalAlcoholPercentage &&
      other.bottlingTotalVolume == bottlingTotalVolume &&
      other.shortageDilution == shortageDilution &&
      other.shortageDilutionPercentage == shortageDilutionPercentage;
  }

  @override
  int get hashCode {
    return tankNumber.hashCode ^
      initialVolume.hashCode ^
      initialDipstick.hashCode ^
      initialAlcoholPercentage.hashCode ^
      dilutionWaterAmount.hashCode ^
      finalVolume.hashCode ^
      finalDipstick.hashCode ^
      finalAlcoholPercentage.hashCode ^
      bottlingTotalVolume.hashCode ^
      shortageDilution.hashCode ^
      shortageDilutionPercentage.hashCode;
  }
}