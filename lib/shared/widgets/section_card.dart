import 'package:flutter/material.dart';

/// セクションカードウィジェット
class SectionCard extends StatelessWidget {
  /// カードのタイトル
  final String title;
  
  /// カードの内容
  final Widget child;
  
  /// アイコン
  final IconData? icon;
  
  /// 右上に表示するアクション
  final Widget? action;
  
  /// アクション前のテキスト
  final String? actionText;
  
  /// パディング
  final EdgeInsetsGeometry padding;
  
  /// マージン
  final EdgeInsetsGeometry margin;

  /// コンストラクタ
  const SectionCard({
    Key? key,
    required this.title,
    required this.child,
    this.icon,
    this.action,
    this.actionText,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16.0),
            child,
          ],
        ),
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        if (action != null) ...[
          Row(
            children: [
              if (actionText != null) ...[
                Text(actionText!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 4.0),
              ],
              action!,
            ],
          ),
        ],
      ],
    );
  }

  /// セクションカードをアコーディオン（展開・折りたたみ可能）として作成
  static Widget accordion({
    required String title,
    required Widget child,
    IconData? icon,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8.0),
    bool initialExpanded = false,
  }) {
    return AccordionSectionCard(
      title: title,
      child: child,
      icon: icon,
      padding: padding,
      margin: margin,
      initialExpanded: initialExpanded,
    );
  }
}

/// アコーディオン（展開・折りたたみ可能）なセクションカード
class AccordionSectionCard extends StatefulWidget {
  /// カードのタイトル
  final String title;
  
  /// カードの内容
  final Widget child;
  
  /// アイコン
  final IconData? icon;
  
  /// パディング
  final EdgeInsetsGeometry padding;
  
  /// マージン
  final EdgeInsetsGeometry margin;
  
  /// 最初から展開状態かどうか
  final bool initialExpanded;

  /// コンストラクタ
  const AccordionSectionCard({
    Key? key,
    required this.title,
    required this.child,
    this.icon,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
    this.initialExpanded = false,
  }) : super(key: key);

  @override
  State<AccordionSectionCard> createState() => _AccordionSectionCardState();
}

class _AccordionSectionCardState extends State<AccordionSectionCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: widget.margin,
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8.0),
                      ],
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: widget.child,
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}