import 'package:flutter/material.dart';
import '../../core/models/tank.dart';
import '../../core/models/tank_category.dart';
import '../../core/services/tank_data_service.dart';

/// タンク選択ウィジェット
class TankSelector extends StatelessWidget {
  /// 現在選択されているタンク番号
  final String? selectedTankNumber;
  
  /// タンクが選択された時のコールバック
  final Function(String) onTankSelected;
  
  /// タンクデータサービス
  final TankDataService _tankDataService = TankDataService();

  /// コンストラクタ
  TankSelector({
    Key? key,
    this.selectedTankNumber,
    required this.onTankSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'タンク選択',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12.0),
            _buildTankDropdown(context),
          ],
        ),
      ),
    );
  }

  /// タンク選択ドロップダウンを構築
  Widget _buildTankDropdown(BuildContext context) {
    // タンクをカテゴリ別に分類
    final Map<TankCategory, List<Tank>> tanksByCategory = _tankDataService.tanksByCategory;
    
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'タンク番号',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      value: selectedTankNumber,
      isExpanded: true,
      icon: const Icon(Icons.expand_more),
      items: _buildDropdownItems(tanksByCategory),
      onChanged: (value) {
        if (value != null) {
          onTankSelected(value);
        }
      },
      // NULLを許容する設定を追加
      hint: const Text('選択してください'),
    );
  }

  /// ドロップダウンの項目を構築
  List<DropdownMenuItem<String>> _buildDropdownItems(
    Map<TankCategory, List<Tank>> tanksByCategory,
  ) {
    final List<DropdownMenuItem<String>> items = [];
    
    // カテゴリごとにグループ化して追加
    final sortedCategories = TankCategory.values.toList()
      ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
    
    for (final category in sortedCategories) {
      final tanksInCategory = tanksByCategory[category] ?? [];
      
      // カテゴリが空の場合はスキップ
      if (tanksInCategory.isEmpty) {
        continue;
      }
      
      // カテゴリグループヘッダー
      items.add(DropdownMenuItem<String>(
        value: null,
        enabled: false,
        child: Text(
          category.name,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ));
      
      // タンク項目を追加
      for (final tank in tanksInCategory) {
        items.add(DropdownMenuItem<String>(
          value: tank.number,
          child: Text(tank.number),
        ));
      }
    }
    
    return items;
  }
}