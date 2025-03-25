import 'package:flutter/material.dart';
import '../../core/models/approximation_pair.dart';
import '../../core/utils/formatters.dart';

/// 近似値チップウィジェット（改善版）
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

    // 近似値を入力値との差に基づいてソート
    final sortedApproximations = [...approximations]
      ..sort((a, b) => a.absoluteDifference.compareTo(b.absoluteDifference));

    // 差が負のもの（入力値より小さい）とそうでないものに分類
    final smallerValues = sortedApproximations
        .where((pair) => pair.difference < 0)
        .toList()
        ..sort((a, b) => b.difference.compareTo(a.difference)); // 入力値に近い順

    final exactMatch = sortedApproximations
        .where((pair) => pair.isExactMatch || pair.difference == 0)
        .toList();

    final largerValues = sortedApproximations
        .where((pair) => pair.difference > 0)
        .toList()
        ..sort((a, b) => a.difference.compareTo(b.difference)); // 入力値に近い順

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
        if (exactMatch.isNotEmpty)
          _buildChipSection(context, '完全一致', exactMatch),
        if (smallerValues.isNotEmpty)
          _buildChipSection(context, '入力値より小さい', smallerValues),
        if (largerValues.isNotEmpty)
          _buildChipSection(context, '入力値より大きい', largerValues),
      ],
    );
  }

  /// チップセクションを構築
  Widget _buildChipSection(
    BuildContext context,
    String title,
    List<ApproximationPair> pairs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: pairs.map((pair) => _buildChip(context, pair, title)).toList(),
        ),
      ],
    );
  }

  /// 個々のチップを構築
  Widget _buildChip(BuildContext context, ApproximationPair pair, String category) {
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
    
    if (category == '完全一致') {
      // 完全一致（緑系）
      chipColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
    } else if (category == '入力値より小さい') {
      // 入力値より小さい（青系）
      chipColor = Colors.blue[50]!;
      textColor = Colors.blue[800]!;
    } else {
      // 入力値より大きい（オレンジ系）
      chipColor = Colors.orange[50]!;
      textColor = Colors.orange[800]!;
    }

    // 最近傍の値は枠線で強調
    final bool isHighlighted = pair.isClosest || pair.isExactMatch;

    return ActionChip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valueText,
            style: TextStyle(
              color: textColor,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
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
          ? BorderSide(color: textColor, width: 1.5)
          : BorderSide(color: Colors.grey[300]!),
      elevation: isHighlighted ? 2 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: () => onSelected(pair),
    );
  }
}