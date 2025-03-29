import 'package:flutter/material.dart';

class ScrollSelector<T> extends StatefulWidget {
  // 既存のプロパティはそのまま
  final List<T> items;
  final String Function(T) labelBuilder;
  final String Function(T)? detailBuilder;
  final T? selectedItem;
  final void Function(T) onItemSelected;
  final int visibleItemCount;
  final double itemHeight;
  final double? width;
  final double? maxHeight;
  final Color? selectedColor;
  final Color? selectedTextColor;
  final Color? unselectedColor;
  final Color? unselectedTextColor;
  
  // 並び順制御用の比較関数
  final int Function(T a, T b)? sortComparator;

  const ScrollSelector({
    Key? key,
    required this.items,
    required this.labelBuilder,
    this.detailBuilder,
    this.selectedItem,
    required this.onItemSelected,
    this.visibleItemCount = 3, // デフォルトを3に変更
    this.itemHeight = 35.0,
    this.width,
    this.maxHeight,
    this.selectedColor,
    this.selectedTextColor,
    this.unselectedColor,
    this.unselectedTextColor,
    this.sortComparator,
  }) : super(key: key);

  @override
  State<ScrollSelector<T>> createState() => _ScrollSelectorState<T>();
}

class _ScrollSelectorState<T> extends State<ScrollSelector<T>> {
  late final ScrollController _scrollController;
  late int _selectedIndex;
  bool _isScrolling = false;
  late List<T> _sortedItems;

  @override
  void initState() {
    super.initState();
    
    // アイテムのソート
    _sortItems();
    
    // 初期選択アイテムのインデックスを設定
    _selectedIndex = widget.selectedItem != null && _sortedItems.isNotEmpty
        ? _sortedItems.indexOf(widget.selectedItem!)
        : 0;
        
    if (_selectedIndex < 0 || _selectedIndex >= _sortedItems.length) _selectedIndex = 0;
    
    // スクロールコントローラの初期化
    _scrollController = ScrollController(
      initialScrollOffset: _sortedItems.isNotEmpty ? _selectedIndex * widget.itemHeight : 0.0,
    );
    
    // スクロール停止時のリスナーを追加
    _scrollController.addListener(_onScrollChanged);
  }

  void _sortItems() {
    _sortedItems = List.from(widget.items);
    if (widget.sortComparator != null) {
      _sortedItems.sort(widget.sortComparator!);
    }
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
    
    // アイテムまたはソート条件が変わった場合は再ソート
    if (widget.items != oldWidget.items || widget.sortComparator != oldWidget.sortComparator) {
      _sortItems();
    }
    
    // 選択アイテムが外部から変更された場合
    if (widget.selectedItem != null && widget.selectedItem != oldWidget.selectedItem) {
      final newIndex = _sortedItems.indexOf(widget.selectedItem!);
      if (newIndex >= 0 && newIndex != _selectedIndex) {
        _selectedIndex = newIndex;
        _scrollToSelectedItem(animate: true);
      }
    }
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients || _isScrolling || _sortedItems.isEmpty) return;
    
    // スクロール停止時の処理
    final itemIndex = (_scrollController.offset / widget.itemHeight).round();
    
    if (itemIndex >= 0 && itemIndex < _sortedItems.length && itemIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = itemIndex;
      });
      
      // 選択変更コールバックを呼び出し
      widget.onItemSelected(_sortedItems[_selectedIndex]);
    }
  }

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
                // スクロール終了時に最も近いアイテムにスナップ
                final itemIndex = (_scrollController.offset / widget.itemHeight).round();
                if (itemIndex != _selectedIndex) {
                  _selectedIndex = itemIndex.clamp(0, _sortedItems.length - 1);
                  _scrollToSelectedItem();
                }
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _sortedItems.length,
              itemExtent: widget.itemHeight,
              physics: const BouncingScrollPhysics(), // 自然なスクロール
              itemBuilder: (context, index) {
                final item = _sortedItems[index];
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? selectedFgColor : unselectedFgColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        if (detail != null)
                          Text(
                            detail,
                            style: TextStyle(
                              color: (isSelected ? selectedFgColor : unselectedFgColor).withOpacity(0.8),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.end,
                          ),
                      ],
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