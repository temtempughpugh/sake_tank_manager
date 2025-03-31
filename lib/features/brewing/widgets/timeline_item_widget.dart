import 'package:flutter/material.dart';

/// タイムラインの各項目の種類
enum TimelineItemType {
  bottling(
    title: '瓶詰め',
    color: Color(0xFFFF7043),
    iconData: Icons.liquor,
    bgColor: Color(0xFFFFE0B2),
  ),
  dilution(
    title: '割水',
    color: Color(0xFF42A5F5),
    iconData: Icons.water_drop,
    bgColor: Color(0xFFBBDEFB),
  ),
  extraction(
    title: '蔵出し',
    color: Color(0xFF66BB6A),
    iconData: Icons.inventory_2,
    bgColor: Color(0xFFC8E6C9),
  ),
  movement(
    title: 'タンク移動',
    color: Color(0xFFAB47BC),
    iconData: Icons.swap_horiz,
    bgColor: Color(0xFFE1BEE7),
  ),
  shortage(
    title: '欠減',
    color: Color(0xFFF44336),
    iconData: Icons.remove_circle_outline,
    bgColor: Color(0xFFFFCDD2),
  );

  const TimelineItemType({
    required this.title,
    required this.color,
    required this.iconData,
    required this.bgColor,
  });

  final String title;
  final Color color;
  final IconData iconData;
  final Color bgColor;
}

/// タイムラインアイテムウィジェット
class TimelineItemWidget extends StatelessWidget {
  /// アイテムの種類
  final TimelineItemType type;
  
  /// タイトル
  final String title;
  
  /// 内容テキストのリスト
  final List<String> contentLines;
  
  /// アイテムの大きさ（通常またはコンパクト）
  final bool isCompact;
  
  /// 最後のアイテムかどうか
  final bool isLast;
  
  /// タップされた時のコールバック
  final VoidCallback? onTap;

  /// コンストラクタ
  const TimelineItemWidget({
    Key? key,
    required this.type,
    required this.title,
    required this.contentLines,
    this.isCompact = false,
    this.isLast = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイムラインの縦線と丸
          _buildTimelineIndicator(),
          
          const SizedBox(width: 12.0),
          
          // 内容カード
          Expanded(
            child: _buildContentCard(context),
          ),
        ],
      ),
    );
  }

  /// タイムラインの縦線と丸を構築
  Widget _buildTimelineIndicator() {
    return SizedBox(
      width: 30.0,
      child: Column(
        children: [
          // 円形アイコン
          Container(
            width: isCompact ? 16.0 : 30.0,
            height: isCompact ? 16.0 : 30.0,
            decoration: BoxDecoration(
              color: type.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isCompact
                ? null
                : Icon(
                    type.iconData,
                    color: Colors.white,
                    size: 18.0,
                  ),
          ),
          
          // 縦線（最後のアイテム以外）
          if (!isLast)
            Expanded(
              child: Container(
                width: 2.0,
                margin: EdgeInsets.only(
                  left: isCompact ? 7.0 : 14.0,
                ),
                color: Colors.grey[300],
              ),
            ),
        ],
      ),
    );
  }

  /// 内容カードを構築
  Widget _buildContentCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: type.color.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      color: type.bgColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: type.color.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8.0),
              
              // 内容テキスト
              ...contentLines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )),
              
              // 編集ボタン（onTapがある場合）
              if (onTap != null && !isCompact)
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.edit,
                    size: 18.0,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}