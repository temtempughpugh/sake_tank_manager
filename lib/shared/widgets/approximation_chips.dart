import 'package:flutter/material.dart';
import '../../core/models/approximation_pair.dart';
import '../../core/utils/formatters.dart';

/// 近似値チップウィジェット
class ApproximationChips extends StatelessWidget {
  /// 近似値のリスト
  final List<ApproximationPair> approximations;
  
  /// ディプスティックモードかどうか（trueなら検尺、falseなら容量）
  final bool isDipstickMode;
  
  /// 値が選択された時のコールバック
  final Function(ApproximationPair) onSelected;

  /// コンストラクタ
  const ApproximationChips({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '近似値から選択:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: approximations.map((pair) => _buildChip(context, pair)).toList(),
        ),
      ],
    );
  }

  /// 個々のチップを構築
  Widget _buildChip(BuildContext context, ApproximationPair pair) {
    final bool isHighlighted = pair.isExactMatch || pair.isClosest;
    
    // チップの表示テキスト（検尺または容量）
    final String valueText = isDipstickMode
        ? Formatters.dipstick(pair.data.dipstick)
        : Formatters.volume(pair.data.volume);
    
    // 補足テキスト（逆の値）
    final String detailText = isDipstickMode
        ? Formatters.volume(pair.data.volume)
        : Formatters.dipstick(pair.data.dipstick);
    
    // チップの状態に応じた色設定
    Color chipColor;
    Color textColor;
    
    if (pair.isExactMatch) {
      // 完全一致（強調表示）
      chipColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    } else if (pair.isClosest) {
      // 最近傍（弱い強調表示）
      chipColor = Theme.of(context).colorScheme.primaryContainer;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;
    } else {
      // 通常表示
      chipColor = Theme.of(context).colorScheme.surface;
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    return ActionChip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valueText,
            style: TextStyle(
              color: textColor,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            detailText,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
      backgroundColor: chipColor,
      side: isHighlighted
          ? BorderSide(color: Theme.of(context).colorScheme.primary)
          : BorderSide(color: Colors.grey.shade300),
      elevation: isHighlighted ? 2 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: () => onSelected(pair),
    );
  }
}