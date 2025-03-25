import 'package:flutter/material.dart';

/// 結果表示用カードウィジェット
class ResultCard extends StatelessWidget {
  /// カードのタイトル
  final String title;
  
  /// 結果値のテキスト
  final String resultText;
  
  /// 補足説明
  final String? description;
  
  /// アイコン
  final IconData? icon;
  
  /// カードの色
  final Color? color;
  
  /// テキストのスタイル
  final TextStyle? textStyle;
  
  /// エラー状態かどうか
  final bool isError;

  /// コンストラクタ
  const ResultCard({
    Key? key,
    required this.title,
    required this.resultText,
    this.description,
    this.icon,
    this.color,
    this.textStyle,
    this.isError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final cardColor = isError 
        ? theme.colorScheme.errorContainer
        : (color ?? theme.colorScheme.surfaceVariant);
    
    final textColor = isError
        ? theme.colorScheme.onErrorContainer
        : (textStyle?.color ?? theme.colorScheme.onSurfaceVariant);
    
    final resultStyle = (textStyle ?? theme.textTheme.headlineSmall)!
        .copyWith(color: textColor);
    
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor),
                  const SizedBox(width: 8.0),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              resultText,
              style: resultStyle,
            ),
            if (description != null) ...[
              const SizedBox(height: 8.0),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// エラー用の結果カードを作成するファクトリコンストラクタ
  factory ResultCard.error({
    required String title,
    required String errorMessage,
  }) {
    return ResultCard(
      title: title,
      resultText: errorMessage,
      icon: Icons.error_outline,
      isError: true,
    );
  }
}