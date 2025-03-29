/// タンク移動工程の記録を表すモデルクラス
class MovementStage {
  /// 移動ID
  final String id;
  
  /// 移動元タンク番号
  final String sourceTankNumber;
  
  /// 移動先タンク番号
  final String destinationTankNumber;
  
  /// 移動量 (L)
  final double movementVolume;
  
  /// 移動元検尺値 (mm)
  final double sourceDipstick;
  
  /// 移動先検尺値 (mm)
  final double destinationDipstick;
  
  /// 移動元タンク残量 (L)
  final double sourceRemainingVolume;
  
  /// 移動元残量検尺値 (mm)
  final double sourceRemainingDipstick;
  
  /// 移動前タンク総量 (L) - 移動量 + 残量
  final double sourceInitialVolume;
  
  /// 欠減量 (L) - 移動量と次工程数量の差
  final double shortageMovement;
  
  /// 欠減率 (%) - 欠減量 / 移動量 * 100
  final double shortageMovementPercentage;
  
  /// 工程名（例: 火入れ、ろ過など）
  final String? processName;
  
  /// 備考
  final String? notes;

  /// コンストラクタ
  MovementStage({
    required this.id,
    required this.sourceTankNumber,
    required this.destinationTankNumber,
    required this.movementVolume,
    required this.sourceDipstick,
    required this.destinationDipstick,
    required this.sourceRemainingVolume,
    required this.sourceRemainingDipstick,
    required this.sourceInitialVolume,
    required this.shortageMovement,
    required this.shortageMovementPercentage,
    this.processName,
    this.notes,
  });

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceTankNumber': sourceTankNumber,
      'destinationTankNumber': destinationTankNumber,
      'movementVolume': movementVolume,
      'sourceDipstick': sourceDipstick,
      'destinationDipstick': destinationDipstick,
      'sourceRemainingVolume': sourceRemainingVolume,
      'sourceRemainingDipstick': sourceRemainingDipstick,
      'sourceInitialVolume': sourceInitialVolume,
      'shortageMovement': shortageMovement,
      'shortageMovementPercentage': shortageMovementPercentage,
      'processName': processName,
      'notes': notes,
    };
  }

  /// Map形式から復元
  factory MovementStage.fromMap(Map<String, dynamic> map) {
    return MovementStage(
      id: map['id'],
      sourceTankNumber: map['sourceTankNumber'],
      destinationTankNumber: map['destinationTankNumber'],
      movementVolume: map['movementVolume'],
      sourceDipstick: map['sourceDipstick'],
      destinationDipstick: map['destinationDipstick'],
      sourceRemainingVolume: map['sourceRemainingVolume'],
      sourceRemainingDipstick: map['sourceRemainingDipstick'],
      sourceInitialVolume: map['sourceInitialVolume'],
      shortageMovement: map['shortageMovement'],
      shortageMovementPercentage: map['shortageMovementPercentage'],
      processName: map['processName'],
      notes: map['notes'],
    );
  }

  /// コピーして新しいインスタンスを作成
  MovementStage copyWith({
    String? id,
    String? sourceTankNumber,
    String? destinationTankNumber,
    double? movementVolume,
    double? sourceDipstick,
    double? destinationDipstick,
    double? sourceRemainingVolume,
    double? sourceRemainingDipstick,
    double? sourceInitialVolume,
    double? shortageMovement,
    double? shortageMovementPercentage,
    String? processName,
    String? notes,
  }) {
    return MovementStage(
      id: id ?? this.id,
      sourceTankNumber: sourceTankNumber ?? this.sourceTankNumber,
      destinationTankNumber: destinationTankNumber ?? this.destinationTankNumber,
      movementVolume: movementVolume ?? this.movementVolume,
      sourceDipstick: sourceDipstick ?? this.sourceDipstick,
      destinationDipstick: destinationDipstick ?? this.destinationDipstick,
      sourceRemainingVolume: sourceRemainingVolume ?? this.sourceRemainingVolume,
      sourceRemainingDipstick: sourceRemainingDipstick ?? this.sourceRemainingDipstick,
      sourceInitialVolume: sourceInitialVolume ?? this.sourceInitialVolume,
      shortageMovement: shortageMovement ?? this.shortageMovement,
      shortageMovementPercentage: shortageMovementPercentage ?? this.shortageMovementPercentage,
      processName: processName ?? this.processName,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'MovementStage(id: $id, sourceTankNumber: $sourceTankNumber, destinationTankNumber: $destinationTankNumber, movementVolume: $movementVolume, sourceDipstick: $sourceDipstick, destinationDipstick: $destinationDipstick, sourceRemainingVolume: $sourceRemainingVolume, sourceRemainingDipstick: $sourceRemainingDipstick, sourceInitialVolume: $sourceInitialVolume, shortageMovement: $shortageMovement, shortageMovementPercentage: $shortageMovementPercentage, processName: $processName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is MovementStage &&
      other.id == id &&
      other.sourceTankNumber == sourceTankNumber &&
      other.destinationTankNumber == destinationTankNumber &&
      other.movementVolume == movementVolume &&
      other.sourceDipstick == sourceDipstick &&
      other.destinationDipstick == destinationDipstick &&
      other.sourceRemainingVolume == sourceRemainingVolume &&
      other.sourceRemainingDipstick == sourceRemainingDipstick &&
      other.sourceInitialVolume == sourceInitialVolume &&
      other.shortageMovement == shortageMovement &&
      other.shortageMovementPercentage == shortageMovementPercentage &&
      other.processName == processName &&
      other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      sourceTankNumber.hashCode ^
      destinationTankNumber.hashCode ^
      movementVolume.hashCode ^
      sourceDipstick.hashCode ^
      destinationDipstick.hashCode ^
      sourceRemainingVolume.hashCode ^
      sourceRemainingDipstick.hashCode ^
      sourceInitialVolume.hashCode ^
      shortageMovement.hashCode ^
      shortageMovementPercentage.hashCode ^
      processName.hashCode ^
      notes.hashCode;
  }
}