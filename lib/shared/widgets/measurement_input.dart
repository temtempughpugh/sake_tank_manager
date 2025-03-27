import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/formatters.dart';

/// 検尺・容量入力用のウィジェット
class MeasurementInput extends StatelessWidget {
  /// 入力フィールドのラベル
  final String label;
  
  /// 入力フィールドのヒント
  final String? hint;
  
  /// コントローラー
  final TextEditingController controller;
  
  /// 単位テキスト（接尾辞）
  final String? suffix;
  
  /// フォーカスノード
  final FocusNode? focusNode;
  
  /// 入力値が変更された時のコールバック
  final Function(String)? onChanged;
  
  /// 入力完了時のコールバック
  final Function(String)? onSubmitted;
  
  /// バリデーション関数
  final String? Function(String?)? validator;
  
  /// 初期値
  final String? initialValue;
  
  /// 入力タイプ
  final TextInputType keyboardType;
  
  /// テキスト入力フォーマッター
  final List<TextInputFormatter>? inputFormatters;
  
  /// アイコン
  final IconData? icon;
  
  /// 読み取り専用かどうか
  final bool readOnly;
  
  /// プレフィックスウィジェット
  final Widget? prefix;
  
  /// 自動フォーカスするかどうか
  final bool autofocus;

  /// コンストラクタ
  const MeasurementInput({
    Key? key,
    required this.label,
    required this.controller,
    this.hint,
    this.suffix,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.initialValue,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.icon,
    this.readOnly = false,
    this.prefix,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon) : prefix,
        suffixText: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      inputFormatters: inputFormatters ?? [
        DecimalTextInputFormatter(decimalRange: 1),
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      readOnly: readOnly,
      autofocus: autofocus,
    );
  }

  /// 検尺値入力用のファクトリーコンストラクタ
  factory MeasurementInput.dipstick({
    required TextEditingController controller,
    FocusNode? focusNode,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
    String? initialValue,
    String? hint,
    bool readOnly = false,
    bool autofocus = false,
  }) {
    return MeasurementInput(
      label: '検尺値',
      hint: hint ?? '0 ~ 2000',
      controller: controller,
      suffix: 'mm',
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      initialValue: initialValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      icon: Icons.straighten,
      readOnly: readOnly,
      autofocus: autofocus,
    );
  }

  /// 容量入力用のファクトリーコンストラクタ
  factory MeasurementInput.volume({
    required TextEditingController controller,
    FocusNode? focusNode,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
    String? initialValue,
    String? hint,
    bool readOnly = false,
    bool autofocus = false,
  }) {
    return MeasurementInput(
      label: '容量',
      hint: hint ?? '0.0 ~ 3000.0',
      controller: controller,
      suffix: 'L',
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      initialValue: initialValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        DecimalTextInputFormatter(decimalRange: 1),
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      icon: Icons.water_drop_outlined,
      readOnly: readOnly,
      autofocus: autofocus,
    );
  }

  /// アルコール度数入力用のファクトリーコンストラクタ
  factory MeasurementInput.alcohol({
  required TextEditingController controller,
  FocusNode? focusNode,
  Function(String)? onChanged,
  Function(String)? onSubmitted,
  String? Function(String?)? validator,
  String? initialValue,
  bool readOnly = false,
  bool autofocus = false,
  String label = 'アルコール度数',  // ラベルパラメーターを追加
}) {
  return MeasurementInput(
    label: label,  // カスタムラベルを使用
    hint: '0.0 ~ 100.0',
    controller: controller,
      suffix: '%',
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator,
      initialValue: initialValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        DecimalTextInputFormatter(decimalRange: 1),
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      icon: Icons.percent,
      readOnly: readOnly,
      autofocus: autofocus,
    );
  }
}