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

  // サービスプロバイダーのセットアップ
  final providers = await ServiceLocator.setupProviders();

  // アプリの起動
  runApp(
    MultiProvider(
      providers: providers,
      child: const SakeTankApp(),
    ),
  );
}

