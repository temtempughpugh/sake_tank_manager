/// 瓶詰め情報を表すモデルクラス
class BottlingInfo {
  /// 瓶詰めID
  final String id;
  
  /// 日付
  final DateTime date;
  
  /// 酒名
  final String sakeName;
  
  /// アルコール度数
  final double alcoholPercentage;
  
  /// 品温（℃）
  final double? temperature;
  
  /// 瓶種リスト
  final List<BottleEntry> bottleEntries;
  
  /// 詰残量（1.8L換算で何本分か）
  final double remainingAmount;
  
  /// 完了フラグ
  final bool isCompleted;
  
  /// 作成日時
  final DateTime createdAt;

  /// コンストラクタ
  BottlingInfo({
    required this.id,
    required this.date,
    required this.sakeName,
    required this.alcoholPercentage,
    this.temperature,
    required this.bottleEntries,
    required this.remainingAmount,
    this.isCompleted = false,
    required this.createdAt,
  });

  /// 総本数を計算
  int get totalBottles {
    return bottleEntries.fold(0, (sum, entry) => sum + entry.totalBottles);
  }

  /// 総容量をリットル単位で計算
  double get totalVolume {
    return bottleEntries.fold(0.0, (sum, entry) => sum + entry.totalVolume);
  }

  /// 詰残を含む合計容量
  double get totalVolumeWithRemaining {
    return totalVolume + (remainingAmount * 1.8);
  }

  /// 純アルコール量を計算
  double get pureAlcoholAmount {
    return totalVolumeWithRemaining * alcoholPercentage / 100;
  }

  /// 瓶種ごとの純アルコール量を計算
  Map<String, double> get pureAlcoholByBottleType {
    final result = <String, double>{};
    
    for (final entry in bottleEntries) {
      result[entry.bottleType.name] = entry.totalVolume * alcoholPercentage / 100;
    }
    
    return result;
  }

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'sakeName': sakeName,
      'alcoholPercentage': alcoholPercentage,
      'temperature': temperature,
      'bottleEntries': bottleEntries.map((e) => e.toMap()).toList(),
      'remainingAmount': remainingAmount,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Map形式から復元
  factory BottlingInfo.fromMap(Map<String, dynamic> map) {
    return BottlingInfo(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      sakeName: map['sakeName'],
      alcoholPercentage: map['alcoholPercentage'],
      temperature: map['temperature'],
      bottleEntries: (map['bottleEntries'] as List)
          .map((e) => BottleEntry.fromMap(e))
          .toList(),
      remainingAmount: map['remainingAmount'],
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  /// コピーして新しいインスタンスを作成
  BottlingInfo copyWith({
    String? id,
    DateTime? date,
    String? sakeName,
    double? alcoholPercentage,
    double? temperature,
    List<BottleEntry>? bottleEntries,
    double? remainingAmount,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return BottlingInfo(
      id: id ?? this.id,
      date: date ?? this.date,
      sakeName: sakeName ?? this.sakeName,
      alcoholPercentage: alcoholPercentage ?? this.alcoholPercentage,
      temperature: temperature ?? this.temperature,
      bottleEntries: bottleEntries ?? this.bottleEntries,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 完了済みとしてマーク
  BottlingInfo markAsCompleted() {
    return copyWith(
      isCompleted: true,
    );
  }
}

/// 瓶種の定義
class BottleType {
  /// 瓶種名
  final String name;
  
  /// 容量（ml）
  final int capacity;
  
  /// ケースあたりの本数
  final int bottlesPerCase;

  const BottleType({
    required this.name,
    required this.capacity,
    required this.bottlesPerCase,
  });

  /// 標準の瓶種：一升瓶 (1,800ml)
  static const BottleType isshobin = BottleType(
    name: '一升瓶',
    capacity: 1800,
    bottlesPerCase: 6,
  );

  /// 標準の瓶種：四合瓶 (720ml)
  static const BottleType yongoubin = BottleType(
    name: '四合瓶',
    capacity: 720,
    bottlesPerCase: 12,
  );

  /// 標準の瓶種：小瓶 (300ml)
  static const BottleType kobin = BottleType(
    name: '小瓶',
    capacity: 300,
    bottlesPerCase: 24,
  );

  /// 標準の瓶種：小瓶2 (180ml)
  static const BottleType kobin2 = BottleType(
    name: '小瓶2',
    capacity: 180,
    bottlesPerCase: 40,
  );

  /// 標準の瓶種リスト
  static const List<BottleType> standardTypes = [
    isshobin,
    yongoubin,
    kobin,
    kobin2,
  ];

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'bottlesPerCase': bottlesPerCase,
    };
  }

  /// Map形式から復元
  factory BottleType.fromMap(Map<String, dynamic> map) {
    return BottleType(
      name: map['name'],
      capacity: map['capacity'],
      bottlesPerCase: map['bottlesPerCase'],
    );
  }
}

/// 瓶詰めエントリーを表すモデルクラス
class BottleEntry {
  /// 瓶種
  final BottleType bottleType;
  
  /// ケース数
  final int cases;
  
  /// バラ本数（ケースに満たない本数）
  final int bottles;

  /// コンストラクタ
  BottleEntry({
    required this.bottleType,
    required this.cases,
    required this.bottles,
  });

  /// 総本数を計算
  int get totalBottles {
    return (cases * bottleType.bottlesPerCase) + bottles;
  }

  /// 総容量をリットル単位で計算
  double get totalVolume {
    return totalBottles * bottleType.capacity / 1000;
  }

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'bottleType': bottleType.toMap(),
      'cases': cases,
      'bottles': bottles,
    };
  }

  /// Map形式から復元
  factory BottleEntry.fromMap(Map<String, dynamic> map) {
    return BottleEntry(
      bottleType: BottleType.fromMap(map['bottleType']),
      cases: map['cases'],
      bottles: map['bottles'],
    );
  }
}