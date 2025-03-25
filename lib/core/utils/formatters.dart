import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 書式設定ユーティリティクラス
class Formatters {
  // プライベートコンストラクタ (インスタンス化防止)
  Formatters._();

  /// 固定小数点表示 (1桁)
  static String fixed1(double value) {
    return value.toStringAsFixed(1);
  }

  /// 固定小数点表示 (2桁)
  static String fixed2(double value) {
    return value.toStringAsFixed(2);
  }

  /// 検尺値の表示書式
  /// - [dipstick]: 検尺値(mm)
  /// - 戻り値: 「XXX mm」形式の文字列
  static String dipstick(double dipstick) {
    return '${dipstick.toStringAsFixed(0)} mm';
  }

  /// 容量の表示書式
  /// - [volume]: 容量(L)
  /// - 戻り値: 「X,XXX.X L」形式の文字列
  static String volume(double volume) {
    final formatter = NumberFormat('#,##0.0', 'ja_JP');
    return '${formatter.format(volume)} L';
  }

  /// アルコール度数の表示書式
  /// - [percentage]: アルコール度数(%)
  /// - 戻り値: 「XX.X%」形式の文字列
  static String alcoholPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// 日付の表示書式
  /// - [date]: 日付
  /// - 戻り値: 「YYYY/MM/DD」形式の文字列
  static String dateFormat(DateTime date) {
    final formatter = DateFormat('yyyy/MM/dd', 'ja_JP');
    return formatter.format(date);
  }

  /// 日時の表示書式
  /// - [dateTime]: 日時
  /// - 戻り値: 「YYYY/MM/DD HH:MM」形式の文字列
  static String dateTimeFormat(DateTime dateTime) {
    final formatter = DateFormat('yyyy/MM/dd HH:mm', 'ja_JP');
    return formatter.format(dateTime);
  }
}

/// 小数入力用のTextInputFormatter
class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({required this.decimalRange})
      : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, 
    TextEditingValue newValue
  ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;

    String value = newValue.text;

    if (value.contains(".") &&
        value.substring(value.indexOf(".") + 1).length > decimalRange) {
      truncated = oldValue.text;
      newSelection = oldValue.selection;
    } else if (value == ".") {
      truncated = "0.";

      newSelection = newValue.selection.copyWith(
        baseOffset: min(truncated.length, truncated.length + 1),
        extentOffset: min(truncated.length, truncated.length + 1),
      );
    }

    return TextEditingValue(
      text: truncated,
      selection: newSelection,
      composing: TextRange.empty,
    );
  }

  static int min(int a, int b) {
    return (a < b) ? a : b;
  }
}

/// 数値のみ入力可能なTextInputFormatter
class NumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, 
    TextEditingValue newValue
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 数字のみを許可
    if (RegExp(r'^[0-9]+$').hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}