/// タンクのカテゴリ（分類）を表す列挙型
enum TankCategory {
  /// 蔵出しタンク
  kuradashi(
    name: '蔵出しタンク',
    priorityOrder: 1,
    tankNumbers: ['No.16', 'No.58'],
  ),

  /// 貯蔵用サーマルタンク
  thermalStorage(
    name: '貯蔵用サーマルタンク',
    priorityOrder: 2,
    tankNumbers: ['No.40', 'No.42', 'No.87', 'No.131', 'No.132', 'No.135'],
  ),

  /// 貯蔵用タンク(冷蔵庫A)
  refrigeratorA(
    name: '貯蔵用タンク(冷蔵庫A)',
    priorityOrder: 3,
    tankNumbers: ['No.69', 'No.70', 'No.71', 'No.72', 'No.39', 'No.84', 'No.38'],
  ),

  /// 貯蔵用タンク(冷蔵庫B)
  refrigeratorB(
    name: '貯蔵用タンク(冷蔵庫B)',
    priorityOrder: 4,
    tankNumbers: ['No.86', 'No.44', 'No.45', 'No.85'],
  ),

  /// 貯蔵用タンク（その他）
  otherStorage(
    name: '貯蔵用タンク（その他）',
    priorityOrder: 5,
    tankNumbers: [],
  ),

  /// 仕込み用タンク
  brewing(
    name: '仕込み用タンク',
    priorityOrder: 6,
    tankNumbers: ['No.262', 'No.263'],
  ),

  /// 水タンク
  water(
    name: '水タンク',
    priorityOrder: 7,
    tankNumbers: ['No.88', '仕込水タンク'],
  ),

  /// その他
  other(
    name: 'その他',
    priorityOrder: 8,
    tankNumbers: [],
  );

  const TankCategory({
    required this.name,
    required this.priorityOrder,
    required this.tankNumbers,
  });

  /// カテゴリ名
  final String name;
  
  /// 表示・選択の優先順位
  final int priorityOrder;
  
  /// このカテゴリに属するタンク番号のリスト
  final List<String> tankNumbers;

  /// タンク番号からカテゴリを判定
  static TankCategory fromTankNumber(String tankNumber) {
    // 優先順位順に検索
    for (final category in TankCategory.values
        .toList()
        ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder))) {
      if (category.tankNumbers.contains(tankNumber)) {
        return category;
      }
    }

    // 特殊ケース（低重要度タンク）
    final lowPriorityTanks = [
      'No.25', 'No.34', 'No.35', 'No.36', 'No.37', 'No.121', 'No.137', 'No.144'
    ];
    if (lowPriorityTanks.contains(tankNumber)) {
      return TankCategory.other;
    }

    // その他の貯蔵用タンク（No.から始まる一般的なタンク）
    if (tankNumber.startsWith('No.')) {
      return TankCategory.otherStorage;
    }

    // 上記以外
    return TankCategory.other;
  }
}