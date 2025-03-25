import 'package:flutter/material.dart';

/// 手動入力フィールドウィジェット
/// - 自動/手動切り替え可能な入力フィールド
class ManualInputField extends StatelessWidget {
  /// 入力フィールドのラベル
  final String label;
  
  /// 自動値（手動入力無効時の表示値）
  final String autoValue;
  
  /// 手動入力時のコントローラー
  final TextEditingController manualController;
  
  /// 単位テキスト（接尾辞）
  final String? suffix;
  
  /// 手動入力が有効かどうか
  final bool isManualEnabled;
  
  /// 手動入力切替時のコールバック
  final Function(bool)? onManualToggled;

  /// テキスト入力完了時のコールバック
  final Function(String)? onSubmitted;

  /// コンストラクタ
  const ManualInputField({
    Key? key,
    required this.label,
    required this.autoValue,
    required this.manualController,
    this.suffix,
    required this.isManualEnabled,
    this.onManualToggled,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: manualController,
            enabled: isManualEnabled,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixText: suffix,
              // 手動入力が無効な場合は自動値を表示
              hintText: isManualEnabled ? null : autoValue,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onFieldSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(width: 8.0),
        Column(
          children: [
            const SizedBox(height: 8.0), // ラベルとスイッチの位置を合わせるための調整
            Row(
              children: [
                Text(
                  isManualEnabled ? '手動' : '自動',
                  style: TextStyle(
                    fontSize: 12,
                    color: isManualEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Switch(
                  value: isManualEnabled,
                  onChanged: onManualToggled,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}