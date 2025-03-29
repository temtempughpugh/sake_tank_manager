/// 瓶詰め情報の更新履歴を表すモデルクラス
class BottlingInfoUpdate {
  /// 更新前アルコール度数 (%)
  final double previousAlcoholPercentage;
  
  /// 更新後アルコール度数 (%)
  final double updatedAlcoholPercentage;
  
  /// 更新前純アルコール量 (L)
  final double previousPureAlcoholAmount;
  
  /// 更新後純アルコール量 (L)
  final double updatedPureAlcoholAmount;
  
  /// 更新日時
  final DateTime updatedAt;
  
  /// 更新理由
  final String? updateReason;

  /// コンストラクタ
  BottlingInfoUpdate({
    required this.previousAlcoholPercentage,
    required this.updatedAlcoholPercentage,
    required this.previousPureAlcoholAmount,
    required this.updatedPureAlcoholAmount,
    required this.updatedAt,
    this.updateReason,
  });

  /// 変化率を計算 (アルコール度数)
  double get alcoholPercentageChangeRate {
    return ((updatedAlcoholPercentage - previousAlcoholPercentage) / previousAlcoholPercentage) * 100;
  }

  /// 変化率を計算 (純アルコール量)
  double get pureAlcoholChangeRate {
    return ((updatedPureAlcoholAmount - previousPureAlcoholAmount) / previousPureAlcoholAmount) * 100;
  }

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'previousAlcoholPercentage': previousAlcoholPercentage,
      'updatedAlcoholPercentage': updatedAlcoholPercentage,
      'previousPureAlcoholAmount': previousPureAlcoholAmount,
      'updatedPureAlcoholAmount': updatedPureAlcoholAmount,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'updateReason': updateReason,
    };
  }

  /// Map形式から復元
  factory BottlingInfoUpdate.fromMap(Map<String, dynamic> map) {
    return BottlingInfoUpdate(
      previousAlcoholPercentage: map['previousAlcoholPercentage'],
      updatedAlcoholPercentage: map['updatedAlcoholPercentage'],
      previousPureAlcoholAmount: map['previousPureAlcoholAmount'],
      updatedPureAlcoholAmount: map['updatedPureAlcoholAmount'],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      updateReason: map['updateReason'],
    );
  }

  /// コピーして新しいインスタンスを作成
  BottlingInfoUpdate copyWith({
    double? previousAlcoholPercentage,
    double? updatedAlcoholPercentage,
    double? previousPureAlcoholAmount,
    double? updatedPureAlcoholAmount,
    DateTime? updatedAt,
    String? updateReason,
  }) {
    return BottlingInfoUpdate(
      previousAlcoholPercentage: previousAlcoholPercentage ?? this.previousAlcoholPercentage,
      updatedAlcoholPercentage: updatedAlcoholPercentage ?? this.updatedAlcoholPercentage,
      previousPureAlcoholAmount: previousPureAlcoholAmount ?? this.previousPureAlcoholAmount,
      updatedPureAlcoholAmount: updatedPureAlcoholAmount ?? this.updatedPureAlcoholAmount,
      updatedAt: updatedAt ?? this.updatedAt,
      updateReason: updateReason ?? this.updateReason,
    );
  }

  @override
  String toString() {
    return 'BottlingInfoUpdate(previousAlcoholPercentage: $previousAlcoholPercentage, updatedAlcoholPercentage: $updatedAlcoholPercentage, previousPureAlcoholAmount: $previousPureAlcoholAmount, updatedPureAlcoholAmount: $updatedPureAlcoholAmount, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is BottlingInfoUpdate &&
      other.previousAlcoholPercentage == previousAlcoholPercentage &&
      other.updatedAlcoholPercentage == updatedAlcoholPercentage &&
      other.previousPureAlcoholAmount == previousPureAlcoholAmount &&
      other.updatedPureAlcoholAmount == updatedPureAlcoholAmount &&
      other.updatedAt == updatedAt &&
      other.updateReason == updateReason;
  }

  @override
  int get hashCode {
    return previousAlcoholPercentage.hashCode ^
      updatedAlcoholPercentage.hashCode ^
      previousPureAlcoholAmount.hashCode ^
      updatedPureAlcoholAmount.hashCode ^
      updatedAt.hashCode ^
      updateReason.hashCode;
  }
}