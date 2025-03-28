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

    // 近似値を値の大小で整列（値が小さい順に）
    final List<ApproximationPair> sortedPairs = List.from(approximations);
    
    if (isDipstickMode) {
      // 検尺モードの場合は検尺値で昇順ソート
      sortedPairs.sort((a, b) => a.data.dipstick.compareTo(b.data.dipstick));
    } else {
      // 容量モードの場合は容量で昇順ソート
      sortedPairs.sort((a, b) => a.data.volume.compareTo(b.data.volume));
    }

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
          children: sortedPairs.map((pair) => _buildChip(context, pair)).toList(),
        ),
      ],
    );
  }

  /// 個々のチップを構築
  Widget _buildChip(BuildContext context, ApproximationPair pair) {
    // チップの表示テキスト（検尺または容量）
    final String valueText = isDipstickMode
        ? '${pair.data.dipstick.toInt()} mm'
        : '${pair.data.volume.toStringAsFixed(1)} L';
    
    // チップの状態に応じた色設定
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
    
    // 差の符号でプレフィックスを追加（↑増加、↓減少）
    String prefix = '';
    if (!pair.isExactMatch) {
      if (isDipstickMode) {
        // 検尺モードでは検尺値が大きいほど容量は少ない（反比例）
        prefix = pair.difference < 0 ? '↑ ' : '↓ ';
      } else {
        // 容量モードでは容量が大きいほど検尺値は小さい（反比例）
        prefix = pair.difference < 0 ? '↓ ' : '↑ ';
      }
    }
    
    // チップのテキスト
    final displayText = prefix + valueText;
    
    // 補足情報 (ツールチップとして表示)
    final String tooltipText = isDipstickMode
        ? '容量: ${pair.data.volume.toStringAsFixed(1)} L'
        : '検尺: ${pair.data.dipstick.toInt()} mm';

    return ActionChip(
      label: Text(
        displayText,
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
      tooltip: tooltipText,
    );
  }
}