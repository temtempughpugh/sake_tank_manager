import 'package:flutter/material.dart';

class ScrollSelector<T> extends StatefulWidget {
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
  final Color? unselectedTextColor;

  const ScrollSelector({
    Key? key,
    required this.items,
    required this.labelBuilder,
    this.detailBuilder,
    this.selectedItem,
    required this.onItemSelected,
    this.visibleItemCount = 3,
    this.itemHeight = 40.0, // 少し高くして見やすく
    this.width,
    this.maxHeight,
    this.selectedColor,
    this.selectedTextColor,
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
        
    if (_selectedIndex < 0 || _selectedIndex >= widget.items.length) {
      _selectedIndex = 0;
    }
    
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
    if (widget.selectedItem != null && widget.selectedItem != oldWidget.selectedItem) {
      final newIndex = widget.items.indexOf(widget.selectedItem!);
      if (newIndex >= 0 && newIndex != _selectedIndex) {
        _selectedIndex = newIndex;
        _scrollToSelectedItem(animate: true);
      }
    }
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients || _isScrolling || widget.items.isEmpty) return;
    
    // スクロール停止時の処理
    final itemIndex = (_scrollController.offset / widget.itemHeight).round();
    
    if (itemIndex >= 0 && itemIndex < widget.items.length && itemIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = itemIndex;
      });
      
      // 選択変更コールバックを呼び出し
      widget.onItemSelected(widget.items[_selectedIndex]);
    }
  }

  /// 選択されたアイテムにスクロール
  Future<void> _scrollToSelectedItem({bool animate = true}) {
    if (!_scrollController.hasClients) return Future.value();
    
    final targetOffset = _selectedIndex * widget.itemHeight;
    
    _isScrolling = true;
    
    if (animate) {
      return _scrollController
          .animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuart,
          )
          .then((_) {
            // アニメーション完了後に少し待ってからフラグを解除
            return Future.delayed(const Duration(milliseconds: 100), () {
              _isScrolling = false;
            });
          });
    } else {
      _scrollController.jumpTo(targetOffset);
      // ジャンプ後に少し待ってからフラグを解除
      return Future.delayed(const Duration(milliseconds: 100), () {
        _isScrolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // デフォルトの色設定
    final selectedBgColor = widget.selectedColor ?? theme.colorScheme.primary;
    final selectedFgColor = widget.selectedTextColor ?? theme.colorScheme.onPrimary;
    final unselectedFgColor = widget.unselectedTextColor ?? theme.colorScheme.onSurface;
    
    // 表示する合計の高さを計算
    final totalHeight = widget.itemHeight * widget.visibleItemCount;
    
    return Container(
      width: widget.width ?? double.infinity,
      height: totalHeight,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification && !_isScrolling) {
            _isScrolling = true;
            
            // スクロール終了時に最も近いアイテムにスナップ
            final offset = _scrollController.offset;
            final itemIndex = (offset / widget.itemHeight).round();
            
            if (itemIndex != _selectedIndex && 
                itemIndex >= 0 && 
                itemIndex < widget.items.length) {
              setState(() {
                _selectedIndex = itemIndex;
              });
              
              // 選択変更コールバックを呼び出し
              widget.onItemSelected(widget.items[_selectedIndex]);
              
              // 完全にスナップさせる
              _scrollToSelectedItem();
            } else {
              // 現在の選択位置に戻す
              _scrollToSelectedItem().then((_) {
                _isScrolling = false;
              });
            }
            
            return true;
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: widget.items.length,
          itemExtent: widget.itemHeight,
          physics: const ClampingScrollPhysics(), // バウンス効果を無効化
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected = index == _selectedIndex;
            
            String label = widget.labelBuilder(item);
            String? detail = widget.detailBuilder?.call(item);
            
            // 表示テキストの統合 - detailがある場合は一行に統合
            String displayText = detail != null 
                ? '$label ($detail)' 
                : label;
            
            return GestureDetector(
              onTap: () {
                if (_isScrolling) return;
                
                setState(() {
                  _selectedIndex = index;
                });
                _scrollToSelectedItem();
                widget.onItemSelected(item);
              },
              child: Container(
                height: widget.itemHeight,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBgColor : Colors.white,
                  border: isSelected 
                      ? Border.all(color: selectedBgColor, width: 2)
                      : null,
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: isSelected ? selectedFgColor : unselectedFgColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}