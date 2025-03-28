import 'package:flutter/material.dart';

/// 結果表示用カードウィジェット（よりコンパクトなサイズに修正）
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
  
  /// パディング（サイズ調整用）
  final EdgeInsetsGeometry padding;

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
    this.padding = const EdgeInsets.all(12.0), // デフォルトパディングを小さく
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
    
    // 結果テキストのスタイルをよりコンパクトに
    final resultStyle = (textStyle ?? theme.textTheme.titleMedium)!
        .copyWith(color: textColor);
    
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6.0), // マージンを小さく
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // タイトルと結果を左右に配置
              children: [
                // 左側: タイトルとアイコン
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: textColor, size: 18), // アイコンサイズ縮小
                      const SizedBox(width: 6.0), // 間隔縮小
                    ],
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                // 右側: 結果テキスト
                Text(
                  resultText,
                  style: resultStyle,
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 4.0), // 間隔縮小
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
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