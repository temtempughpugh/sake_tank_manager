// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'package:provider/provider.dart';
import 'core/services/service_locator.dart';

void main() async {
  // Flutterエンジンの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 画面の向きを縦向きに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // サービスプロバイダーのセットアップ
    // すべてのサービスが完全に初期化されるまで待機
    final providers = await ServiceLocator.setupProviders();
    print('サービスの初期化が完了しました');

    // アプリの起動（初期化完了後）
    runApp(
      MultiProvider(
        providers: providers,
        child: const SakeTankApp(),
      ),
    );
  } catch (e) {
    print('サービスの初期化中にエラーが発生しました: $e');
    // エラーが発生した場合のフォールバックUI
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('起動準備中にエラーが発生しました: $e'),
        ),
      ),
    ));
  }
}