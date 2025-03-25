import 'package:flutter/material.dart';
import '../../core/models/approximation_pair.dart';
import '../../core/utils/formatters.dart';

/// よりコンパクトな近似値チップウィジェット
class CompactApproximationChips extends StatelessWidget {
  /// 近似値のリスト
  final List<ApproximationPair> approximations;
  
  /// ディプスティックモードかどうか（trueなら検尺、falseなら容量）
  final bool isDipstickMode;
  
  /// 値が選択された時のコールバック
  final Function(ApproximationPair) onSelected;

  /// コンストラクタ
  const CompactApproximationChips({
    Key? key,
    required this.approximations,
    required this.isDipstickMode,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (approximations.isEmpty) {
      return const SizedBox.shrink();
    }

    // 近似値を入力値との差に基づいてソート
    final sortedApproximations = [...approximations]
      ..sort((a, b) => a.absoluteDifference.compareTo(b.absoluteDifference));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '近似値候補:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          children: sortedApproximations.map((pair) {
            // 完全一致、最近傍、その他で色を分ける
            Color chipColor;
            Color textColor;
            
            if (pair.isExactMatch) {
              // 完全一致（緑系）
              chipColor = Colors.green[100]!;
              textColor = Colors.green[800]!;
            } else if (pair.isClosest) {
              // 最近傍（青系）
              chipColor = Colors.blue[100]!;
              textColor = Colors.blue[800]!;
            } else {
              // その他（グレー系）
              chipColor = Colors.grey[100]!;
              textColor = Colors.grey[800]!;
            }
            
            // 差の符号でマーカーを追加
            String prefix = '';
            if (!pair.isExactMatch) {
              prefix = pair.difference < 0 ? '↓ ' : '↑ ';
            }
            
            // 主要な値（検尺または容量）
            final String valueText = isDipstickMode
                ? '${prefix}${pair.data.dipstick.toInt()} mm'
                : '${prefix}${pair.data.volume.toStringAsFixed(1)} L';
            
            return ActionChip(
              label: Text(
                valueText,
                style: TextStyle(
                  color: textColor,
                  fontWeight: pair.isExactMatch || pair.isClosest 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              backgroundColor: chipColor,
              side: BorderSide(
                color: pair.isExactMatch || pair.isClosest 
                    ? textColor 
                    : Colors.grey[300]!,
                width: pair.isExactMatch || pair.isClosest ? 1.5 : 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              visualDensity: VisualDensity.compact,
              onPressed: () => onSelected(pair),
              // ツールチップを追加
              tooltip: isDipstickMode
                  ? '容量: ${pair.data.volume.toStringAsFixed(1)} L'
                  : '検尺: ${pair.data.dipstick.toInt()} mm',
            );
          }).toList(),
        ),
      ],
    );
  }
}