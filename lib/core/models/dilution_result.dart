/// 割水計算結果を表すモデルクラス
class DilutionResult {
  /// タンク番号
  final String tankNumber;
  
  /// 初期容量 (L)
  final double initialVolume;
  
  /// 初期検尺値 (mm)
  final double initialDipstick;
  
  /// 初期アルコール度数 (%)
  final double initialAlcoholPercentage;
  
  /// 目標アルコール度数 (%)
  final double targetAlcoholPercentage;
  
  /// 追加水量 (L)
  final double waterAmount;
  
  /// 最終容量 (L)
  final double finalVolume;
  
  /// 最終検尺値 (mm)
  final double finalDipstick;
  
  /// 最終アルコール度数 (%)
  final double finalAlcoholPercentage;
  
  /// 酒名（オプション）
  final String? sakeName;
  
  /// 担当者（オプション）
  final String? personInCharge;
  
  /// エラーメッセージ (エラーがある場合)
  final String? errorMessage;

  /// コンストラクタ
  DilutionResult({
    required this.tankNumber,
    required this.initialVolume,
    required this.initialDipstick,
    required this.initialAlcoholPercentage,
    required this.targetAlcoholPercentage,
    required this.waterAmount,
    required this.finalVolume,
    required this.finalDipstick,
    required this.finalAlcoholPercentage,
    this.sakeName,
    this.personInCharge,
    this.errorMessage,
  });

  /// エラーがあるかどうか
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// エラー結果を作成するファクトリメソッド
  factory DilutionResult.error(String tankNumber, String message) {
    return DilutionResult(
      tankNumber: tankNumber,
      initialVolume: 0,
      initialDipstick: 0,
      initialAlcoholPercentage: 0,
      targetAlcoholPercentage: 0,
      waterAmount: 0,
      finalVolume: 0,
      finalDipstick: 0,
      finalAlcoholPercentage: 0,
      errorMessage: message,
    );
  }

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'tankNumber': tankNumber,
      'initialVolume': initialVolume,
      'initialDipstick': initialDipstick,
      'initialAlcoholPercentage': initialAlcoholPercentage,
      'targetAlcoholPercentage': targetAlcoholPercentage,
      'waterAmount': waterAmount,
      'finalVolume': finalVolume,
      'finalDipstick': finalDipstick,
      'finalAlcoholPercentage': finalAlcoholPercentage,
      'sakeName': sakeName,
      'personInCharge': personInCharge,
      'errorMessage': errorMessage,
    };
  }

  /// Map形式から復元
  factory DilutionResult.fromMap(Map<String, dynamic> map) {
    return DilutionResult(
      tankNumber: map['tankNumber'],
      initialVolume: map['initialVolume'],
      initialDipstick: map['initialDipstick'],
      initialAlcoholPercentage: map['initialAlcoholPercentage'],
      targetAlcoholPercentage: map['targetAlcoholPercentage'],
      waterAmount: map['waterAmount'],
      finalVolume: map['finalVolume'],
      finalDipstick: map['finalDipstick'],
      finalAlcoholPercentage: map['finalAlcoholPercentage'],
      sakeName: map['sakeName'],
      personInCharge: map['personInCharge'],
      errorMessage: map['errorMessage'],
    );
  }

  @override
  String toString() {
    return 'DilutionResult{tankNumber: $tankNumber, initialVolume: $initialVolume, initialDipstick: $initialDipstick, initialAlcohol: $initialAlcoholPercentage, targetAlcohol: $targetAlcoholPercentage, waterAmount: $waterAmount, finalVolume: $finalVolume, finalDipstick: $finalDipstick, finalAlcohol: $finalAlcoholPercentage${hasError ? ', error: $errorMessage' : ''}}';
  }
}