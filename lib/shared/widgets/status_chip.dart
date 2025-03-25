import 'package:flutter/material.dart';
import '../../features/dilution/models/dilution_plan.dart';

/// ステータスの種類を表す列挙型
enum StatusType {
  /// 進行中
  active(
    label: '進行中',
    background: Color(0xFFE3F2FD),
    textColor: Color(0xFF1565C0),
  ),

  /// まもなく期限
  expiringSoon(
    label: 'まもなく期限',
    background: Color(0xFFFFF3E0),
    textColor: Color(0xFFE65100),
  ),

  /// 期限超過
  expired(
    label: '期限超過',
    background: Color(0xFFFFEBEE),
    textColor: Color(0xFFC62828),
  ),

  /// 完了
  completed(
    label: '完了',
    background: Color(0xFFE8F5E9),
    textColor: Color(0xFF2E7D32),
  ),

  /// カスタム
  custom(
    label: '',
    background: Colors.grey,
    textColor: Colors.black,
  );

  /// コンストラクタ
  const StatusType({
    required this.label,
    required this.background,
    required this.textColor,
  });

  /// 表示ラベル
  final String label;
  
  /// 背景色
  final Color background;
  
  /// テキスト色
  final Color textColor;
}

/// ステータスチップウィジェット
class StatusChip extends StatelessWidget {
  /// ステータスの種類
  final StatusType type;
  
  /// カスタムラベル（typeがcustomの場合に使用）
  final String? customLabel;
  
  /// カスタム背景色（typeがcustomの場合に使用）
  final Color? customBackground;
  
  /// カスタムテキスト色（typeがcustomの場合に使用）
  final Color? customTextColor;
  
  /// パディング
  final EdgeInsetsGeometry padding;
  
  /// ラベルスタイル
  final TextStyle? labelStyle;

  /// コンストラクタ
  const StatusChip({
    Key? key,
    required this.type,
    this.customLabel,
    this.customBackground,
    this.customTextColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
    this.labelStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ラベルの決定
    final String label = type == StatusType.custom 
        ? (customLabel ?? 'カスタム') 
        : type.label;
    
    // 背景色の決定
    final Color backgroundColor = type == StatusType.custom 
        ? (customBackground ?? Colors.grey[100]!) 
        : type.background;
    
    // テキスト色の決定
    final Color textColor = type == StatusType.custom 
        ? (customTextColor ?? Colors.grey[800]!) 
        : type.textColor;
    
    // スタイルの作成
    final TextStyle style = (labelStyle ?? const TextStyle()).copyWith(
      color: textColor,
      fontSize: 12,
    );

    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: style,
      padding: padding,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// 割水計画からステータスチップを作成するファクトリメソッド
  static StatusChip fromDilutionPlan(DilutionPlan plan) {
    if (plan.isCompleted) {
      return const StatusChip(type: StatusType.completed);
    } else if (plan.daysSinceCreation >= 7) {
      return const StatusChip(type: StatusType.expired);
    } else if (plan.daysSinceCreation >= 5) {
      return const StatusChip(type: StatusType.expiringSoon);
    } else {
      return const StatusChip(type: StatusType.active);
    }
  }

  /// カスタムステータスチップを作成するファクトリメソッド
  static StatusChip custom({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 4),
    TextStyle? labelStyle,
  }) {
    return StatusChip(
      type: StatusType.custom,
      customLabel: label,
      customBackground: backgroundColor,
      customTextColor: textColor,
      padding: padding,
      labelStyle: labelStyle,
    );
  }
}