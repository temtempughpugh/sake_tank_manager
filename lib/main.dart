import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/services/tank_data_service.dart';
import 'core/services/storage_service.dart';

void main() async {
  // Flutterエンジンの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 画面の向きを縦向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // サービスの初期化
  await _initializeServices();

  // アプリの起動
  runApp(const SakeTankApp());
}

/// サービスの初期化
Future<void> _initializeServices() async {
  try {
    // ストレージサービスの初期化
    final storageService = StorageService();
    await storageService.initialize();

    // タンクデータサービスの初期化
    final tankDataService = TankDataService();
    await tankDataService.initialize();

    print('サービスの初期化が完了しました');
  } catch (e) {
    print('サービスの初期化中にエラーが発生しました: $e');

    // エラーダイアログを表示する代わりに、ここでは単にエラーをログに出力
    // 本番環境では適切なエラーハンドリングが必要
  }
}