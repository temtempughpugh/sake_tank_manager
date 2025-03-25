/// 入力検証ユーティリティクラス
class Validators {
  // プライベートコンストラクタ (インスタンス化防止)
  Validators._();

  /// 必須入力チェック
  /// - [value]: 検証する値
  /// - [fieldName]: フィールド名（エラーメッセージ用）
  /// - 戻り値: エラーメッセージ（問題なければnull）
  static String? required(String? value, {String fieldName = '入力項目'}) {
    if (value == null || value.isEmpty) {
      return '$fieldNameは必須です';
    }
    return null;
  }

  /// 数値入力チェック
  /// - [value]: 検証する値
  /// - [fieldName]: フィールド名（エラーメッセージ用）
  /// - 戻り値: エラーメッセージ（問題なければnull）
  static String? numeric(String? value, {String fieldName = '入力項目'}) {
    if (value == null || value.isEmpty) {
      return null; // 空の場合は他の検証で対応
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldNameは数値を入力してください';
    }
    
    return null;
  }

  /// 整数入力チェック
  /// - [value]: 検証する値
  /// - [fieldName]: フィールド名（エラーメッセージ用）
  /// - 戻り値: エラーメッセージ（問題なければnull）
  static String? integer(String? value, {String fieldName = '入力項目'}) {
    if (value == null || value.isEmpty) {
      return null; // 空の場合は他の検証で対応
    }
    
    if (int.tryParse(value) == null) {
      return '$fieldNameは整数を入力してください';
    }
    
    return null;
  }

  /// 数値範囲チェック
  /// - [value]: 検証する値
  /// - [min]: 最小値
  /// - [max]: 最大値
  /// - [fieldName]: フィールド名（エラーメッセージ用）
  /// - 戻り値: エラーメッセージ（問題なければnull）
  static String? range(
    String? value, {
    double? min,
    double? max,
    String fieldName = '入力項目',
  }) {
    if (value == null || value.isEmpty) {
      return null; // 空の場合は他の検証で対応
    }
    
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return null; // 数値変換できない場合は他の検証で対応
    }
    
    if (min != null && numValue < min) {
      return '$fieldNameは$min以上にしてください';
    }
    
    if (max != null && numValue > max) {
      return '$fieldNameは$max以下にしてください';
    }
    
    return null;
  }

  /// アルコール度数チェック
  /// - [value]: 検証する値
  /// - 戻り値: エラーメッセージ（問題なければnull）
  static String? alcoholPercentage(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 空の場合は他の検証で対応
    }
    
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return null; // 数値変換できない場合は他の検証で対応
    }
    
    if (numValue <= 0 || numValue > 100) {
      return 'アルコール度数は0〜100%の範囲で入力してください';
    }
    
    return null;
  }

  /// 検尺値チェック
  /// - [value]: 検証する値
  /// - [maxDipstick]: タンクの最大検尺値
  /// - 戻り値: エラーメッセージ（問題なければnull）
  static String? dipstick(String? value, {double? maxDipstick}) {
    if (value == null || value.isEmpty) {
      return null; // 空の場合は他の検証で対応
    }
    
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return null; // 数値変換できない場合は他の検証で対応
    }
    
    if (numValue < 0) {
      return '検尺値は0以上にしてください';
    }
    
    if (maxDipstick != null && numValue > maxDipstick) {
      return '検尺値は最大${maxDipstick.toStringAsFixed(0)}mm以下にしてください';
    }
    
    return null;
  }

  /// 容量チェック
  /// - [value]: 検証する値
  /// - [maxVolume]: タンクの最大容量
  /// - 戻り値: エラーメッセージ（問題なければnull）
  static String? volume(String? value, {double? maxVolume}) {
    if (value == null || value.isEmpty) {
      return null; // 空の場合は他の検証で対応
    }
    
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return null; // 数値変換できない場合は他の検証で対応
    }
    
    if (numValue <= 0) {
      return '容量は0より大きい値にしてください';
    }
    
    if (maxVolume != null && numValue > maxVolume) {
      return '容量は最大${maxVolume.toStringAsFixed(1)}L以下にしてください';
    }
    
    return null;
  }

  /// 複合検証
  /// - 複数の検証関数を組み合わせて検証する
  /// - [value]: 検証する値
  /// - [validators]: 検証関数のリスト
  /// - 戻り値: 最初のエラーメッセージ（問題なければnull）
  static String? compose(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}