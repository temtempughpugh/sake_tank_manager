import '../../../core/models/dilution_result.dart';

/// 割水計画モデルクラス
class DilutionPlan {
  /// 計画ID（一意）
  final String id;
  
  /// 割水計算結果
  final DilutionResult result;
  
  /// 作成日時
  final DateTime createdAt;
  
  /// 計画完了フラグ
  final bool isCompleted;
  
  /// 完了日時
  final DateTime? completedAt;

  /// コンストラクタ
  DilutionPlan({
    required this.id,
    required this.result,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
  });

  /// 計画から経過した日数
  int get daysSinceCreation {
    final now = DateTime.now();
    return now.difference(createdAt).inDays;
  }

  /// コピーして新しいインスタンスを作成
  DilutionPlan copyWith({
    String? id,
    DilutionResult? result,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DilutionPlan(
      id: id ?? this.id,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 完了済みとしてマーク
  DilutionPlan markAsCompleted() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'result': result.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  /// Map形式から復元
  factory DilutionPlan.fromMap(Map<String, dynamic> map) {
    return DilutionPlan(
      id: map['id'],
      result: DilutionResult.fromMap(map['result']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
    );
  }
}