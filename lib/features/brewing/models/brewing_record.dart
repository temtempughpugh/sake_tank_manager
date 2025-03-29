import 'package:flutter/foundation.dart';
import 'dilution_stage.dart';
import 'movement_stage.dart';
import 'bottling_info_update.dart';

/// 記帳サポートの記録全体を表すモデルクラス
class BrewingRecord {
  /// 記録ID
  final String id;
  
  /// 瓶詰め情報ID (BottlingInfo参照用)
  final String bottlingInfoId;
  
  /// 瓶詰め情報が更新されたかどうか
  final bool isBottlingInfoUpdated;
  
  /// 更新された瓶詰め情報
  final BottlingInfoUpdate? bottlingUpdate;
  
  /// 割水ステージ記録
  final DilutionStage? dilutionStage;
  
  /// タンク移動記録リスト (複数のタンク移動を記録)
  final List<MovementStage> movementStages;
  
  /// 作成日時
  final DateTime createdAt;
  
  /// 最終更新日時
  final DateTime updatedAt;
  
  /// 担当者名
  final String? personInCharge;
  
  /// 備考
  final String? notes;

  /// コンストラクタ
  BrewingRecord({
    required this.id,
    required this.bottlingInfoId,
    this.isBottlingInfoUpdated = false,
    this.bottlingUpdate,
    this.dilutionStage,
    List<MovementStage>? movementStages,
    required this.createdAt,
    required this.updatedAt,
    this.personInCharge,
    this.notes,
  }) : movementStages = movementStages ?? [];

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bottlingInfoId': bottlingInfoId,
      'isBottlingInfoUpdated': isBottlingInfoUpdated,
      'bottlingUpdate': bottlingUpdate?.toMap(),
      'dilutionStage': dilutionStage?.toMap(),
      'movementStages': movementStages.map((stage) => stage.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'personInCharge': personInCharge,
      'notes': notes,
    };
  }

  /// Map形式から復元
  factory BrewingRecord.fromMap(Map<String, dynamic> map) {
    return BrewingRecord(
      id: map['id'],
      bottlingInfoId: map['bottlingInfoId'],
      isBottlingInfoUpdated: map['isBottlingInfoUpdated'] ?? false,
      bottlingUpdate: map['bottlingUpdate'] != null 
          ? BottlingInfoUpdate.fromMap(map['bottlingUpdate']) 
          : null,
      dilutionStage: map['dilutionStage'] != null 
          ? DilutionStage.fromMap(map['dilutionStage']) 
          : null,
      movementStages: map['movementStages'] != null 
          ? List<MovementStage>.from(
              (map['movementStages'] as List).map(
                (x) => MovementStage.fromMap(x),
              ),
            ) 
          : [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      personInCharge: map['personInCharge'],
      notes: map['notes'],
    );
  }

  /// コピーして新しいインスタンスを作成
  BrewingRecord copyWith({
    String? id,
    String? bottlingInfoId,
    bool? isBottlingInfoUpdated,
    BottlingInfoUpdate? bottlingUpdate,
    DilutionStage? dilutionStage,
    List<MovementStage>? movementStages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? personInCharge,
    String? notes,
  }) {
    return BrewingRecord(
      id: id ?? this.id,
      bottlingInfoId: bottlingInfoId ?? this.bottlingInfoId,
      isBottlingInfoUpdated: isBottlingInfoUpdated ?? this.isBottlingInfoUpdated,
      bottlingUpdate: bottlingUpdate ?? this.bottlingUpdate,
      dilutionStage: dilutionStage ?? this.dilutionStage,
      movementStages: movementStages ?? this.movementStages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      personInCharge: personInCharge ?? this.personInCharge,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'BrewingRecord(id: $id, bottlingInfoId: $bottlingInfoId, isBottlingInfoUpdated: $isBottlingInfoUpdated, dilutionStage: $dilutionStage, movementStages: $movementStages, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is BrewingRecord &&
      other.id == id &&
      other.bottlingInfoId == bottlingInfoId &&
      other.isBottlingInfoUpdated == isBottlingInfoUpdated &&
      other.bottlingUpdate == bottlingUpdate &&
      other.dilutionStage == dilutionStage &&
      listEquals(other.movementStages, movementStages) &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.personInCharge == personInCharge &&
      other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      bottlingInfoId.hashCode ^
      isBottlingInfoUpdated.hashCode ^
      bottlingUpdate.hashCode ^
      dilutionStage.hashCode ^
      movementStages.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      personInCharge.hashCode ^
      notes.hashCode;
  }
}