import 'package:flutter/material.dart';

/// エラー処理ユーティリティクラス
class ErrorHandler {
  // プライベートコンストラクタ (インスタンス化防止)
  ErrorHandler._();

  /// Snackbarでエラーメッセージを表示
  /// - [context]: BuildContext
  /// - [message]: 表示するエラーメッセージ
  /// - [duration]: 表示時間
  static void showErrorSnackBar(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Snackbarで成功メッセージを表示
  /// - [context]: BuildContext
  /// - [message]: 表示する成功メッセージ
  /// - [duration]: 表示時間
  static void showSuccessSnackBar(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// エラーダイアログを表示
  /// - [context]: BuildContext
  /// - [title]: ダイアログのタイトル
  /// - [message]: 表示するエラーメッセージ
  static Future<void> showErrorDialog(
    BuildContext context, {
    String title = 'エラー',
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 確認ダイアログを表示
  /// - [context]: BuildContext
  /// - [title]: ダイアログのタイトル
  /// - [message]: 表示するメッセージ
  /// - [confirmText]: 確認ボタンのテキスト
  /// - [cancelText]: キャンセルボタンのテキスト
  /// - 戻り値: 確認されたかどうか
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    String title = '確認',
    required String message,
    String confirmText = 'はい',
    String cancelText = 'いいえ',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// テキストフィールドのエラーメッセージを表示形式に変換
  /// - [errorText]: エラーメッセージ
  /// - 戻り値: フォーマットされたエラーテキスト
  static Widget? formatErrorText(String? errorText) {
    if (errorText == null || errorText.isEmpty) {
      return null;
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12),
      child: Text(
        errorText,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12.0,
        ),
      ),
    );
  }
}