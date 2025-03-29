import 'package:flutter/material.dart';

/// 縦スクロール式の数値選択ウィジェット
/// 
/// 複数の選択肢から値を選ぶことができるスクロール型のセレクターです。
/// 中央に選択されたアイテムがハイライト表示されます。
class ScrollSelector<T> extends StatefulWidget {
  /// 選択肢のリスト
  final List<T> items;
  
  /// アイテムの表示方法を定義する関数
  final String Function(T) labelBuilder;
  
  /// 詳細情報の表示方法を定義する関数（オプション）
  final String Function(T)? detailBuilder;
  
  /// 現在選択されているアイテム
  final T? selectedItem;
  
  /// アイテムが選択された時のコールバック
  final void Function(T) onItemSelected;
  
  /// 表示する項目数（奇数が望ましい）
  final int visibleItemCount;
  
  /// アイテムの高さ
  final double itemHeight;
  
  /// セレクターの幅
  final double? width;
  
  /// セレクターの最大高さ
  final double? maxHeight;
  
  /// ハイライト表示する選択項目の背景色
  final Color? selectedColor;
  
  /// ハイライト表示する選択項目のテキスト色
  final Color? selectedTextColor;
  
  /// 非選択項目の背景色
  final Color? unselectedColor;
  
  /// 非選択項目のテキスト色
  final Color? unselectedTextColor;
  
  /// コンストラクタ
  const ScrollSelector({
    Key? key,
    required this.items,
    required this.labelBuilder,
    this.detailBuilder,
    this.selectedItem,
    required this.onItemSelected,
    this.visibleItemCount = 5,
    this.itemHeight = 35.0,
    this.width,
    this.maxHeight,
    this.selectedColor,
    this.selectedTextColor,
    this.unselectedColor,
    this.unselectedTextColor,
  }) : super(key: key);

  @override
  State<ScrollSelector<T>> createState() => _ScrollSelectorState<T>();
}

class _ScrollSelectorState<T> extends State<ScrollSelector<T>> {
  late final ScrollController _scrollController;
  late int _selectedIndex;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    
    // 初期選択アイテムのインデックスを設定
    _selectedIndex = widget.selectedItem != null && widget.items.isNotEmpty
        ? widget.items.indexOf(widget.selectedItem!)
        : 0;
        
    if (_selectedIndex < 0 || _selectedIndex >= widget.items.length) _selectedIndex = 0;
    
    // スクロールコントローラの初期化
    _scrollController = ScrollController(
      initialScrollOffset: widget.items.isNotEmpty ? _selectedIndex * widget.itemHeight : 0.0,
    );
    
    // スクロール停止時のリスナーを追加
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ScrollSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 選択アイテムが外部から変更された場合
    if (widget.selectedItem != null && 
        widget.selectedItem != oldWidget.selectedItem) {
      final newIndex = widget.items.indexOf(widget.selectedItem!);
      if (newIndex >= 0 && newIndex != _selectedIndex) {
        _selectedIndex = newIndex;
        _scrollToSelectedItem(animate: false);
      }
    }
  }

  /// スクロール位置が変更された時の処理
  void _onScrollChanged() {
    if (!_scrollController.hasClients || _isScrolling || widget.items.isEmpty) return;
    
    // スクロール停止時の処理
    final middleOffset = widget.visibleItemCount / 2.0;
    final centerPosition = _scrollController.offset + widget.itemHeight * (middleOffset > 0.5 ? middleOffset - 0.5 : 0);
    final newIndex = (centerPosition / widget.itemHeight).round();
    
    if (newIndex >= 0 && newIndex < widget.items.length && newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
      
      // 選択変更コールバックを呼び出し
      widget.onItemSelected(widget.items[_selectedIndex]);
    }
  }

  /// 選択アイテムにスクロール
  void _scrollToSelectedItem({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    
    final targetOffset = _selectedIndex * widget.itemHeight;
    
    _isScrolling = true;
    
    if (animate) {
      _scrollController
          .animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .then((_) => _isScrolling = false);
    } else {
      _scrollController.jumpTo(targetOffset);
      _isScrolling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // デフォルトの色設定
    final selectedBgColor = widget.selectedColor ?? theme.colorScheme.primary;
    final selectedFgColor = widget.selectedTextColor ?? theme.colorScheme.onPrimary;
    final unselectedBgColor = widget.unselectedColor ?? theme.colorScheme.surface.withOpacity(0.2);
    final unselectedFgColor = widget.unselectedTextColor ?? theme.colorScheme.onSurface;
    
    // 表示する合計の高さを計算
    final totalHeight = widget.itemHeight * widget.visibleItemCount;
    
    return Container(
      width: widget.width ?? double.infinity,
      height: totalHeight,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Stack(
        children: [
          // 選択されたアイテムのハイライト表示
          Positioned(
            top: (widget.visibleItemCount > 1) 
                ? ((widget.visibleItemCount ~/ 2) * widget.itemHeight) 
                : 0,
            left: 0,
            right: 0,
            child: Container(
              height: widget.itemHeight,
              color: selectedBgColor,
            ),
          ),
          
          // スクロール可能なアイテムリスト
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                // スクロール終了時に中央にあるアイテムにスナップ
                final itemIndex = (_scrollController.offset / widget.itemHeight).round();
                if (itemIndex != _selectedIndex) {
                  _selectedIndex = itemIndex.clamp(0, widget.items.length - 1);
                  _scrollToSelectedItem();
                }
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.items.length,
              itemExtent: widget.itemHeight,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = index == _selectedIndex;
                
                String label = widget.labelBuilder(item);
                String? detail = widget.detailBuilder?.call(item);
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    _scrollToSelectedItem();
                    widget.onItemSelected(item);
                  },
                  child: Container(
                    height: widget.itemHeight,
                    color: isSelected ? selectedBgColor : unselectedBgColor,
                    alignment: Alignment.center,
                    child: detail != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? selectedFgColor : unselectedFgColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                detail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (isSelected ? selectedFgColor : unselectedFgColor)
                                      .withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? selectedFgColor : unselectedFgColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}