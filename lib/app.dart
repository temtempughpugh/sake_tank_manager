import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'features/tank_reference/screens/tank_reference_screen.dart';
import 'features/dilution/screens/dilution_screen.dart';
import 'features/dilution/screens/dilution_plans_screen.dart';
import 'features/bottling/screens/bottling_screen.dart';
import 'features/bottling/screens/bottling_list_screen.dart';
import 'features/bottling/models/bottling_info.dart';  
import 'features/brewing/screens/brewing_record_list_screen.dart';

/// アプリケーションのメインクラス
class SakeTankApp extends StatelessWidget {
  /// コンストラクタ
  const SakeTankApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日本酒タンク管理',
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.light, // ライトモード固定（将来的に設定可能にするかも）
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'), // 日本語
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/tank-reference': (context) => const TankReferenceScreen(),
        '/dilution': (context) => const DilutionScreen(),
        '/dilution-plans': (context) => const DilutionPlansScreen(),
        '/bottling': (context) => const BottlingScreen(),
        '/bottling-list': (context) => const BottlingListScreen(),
        '/brewing-records': (context) => const BrewingRecordListScreen(),
      },
      // onGenerateRouteを修正
      onGenerateRoute: (settings) {
        if (settings.name == '/bottling-edit') {
          final bottlingInfo = settings.arguments as BottlingInfo;
          return MaterialPageRoute(
            builder: (context) => BottlingScreen(bottlingInfo: bottlingInfo),
          );
        }
        return null;
      },
      debugShowCheckedModeBanner: false, // デバッグバナーを非表示に
    );
  }

  /// ライトテーマを構築
  ThemeData _buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A5F7A), // 濃い青緑色
      brightness: Brightness.light,
    ),
    // 他の設定は既存のままで、以下を追加
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          bottomLeft: Radius.circular(0),
        ),
      ),
    ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF1A5F7A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontFamily: 'NotoSansJP',
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontFamily: 'NotoSansJP',
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontFamily: 'NotoSansJP',
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontFamily: 'NotoSansJP',
          fontSize: 16,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontFamily: 'NotoSansJP',
          fontSize: 14,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontFamily: 'NotoSansJP',
          fontSize: 12,
        ),
      ),
    );
  }

  /// ダークテーマを構築
  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark(useMaterial3: true);
    
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A5F7A), // 濃い青緑色
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF0D2B36),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontFamily: 'NotoSansJP',
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontFamily: 'NotoSansJP',
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontFamily: 'NotoSansJP',
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontFamily: 'NotoSansJP',
          fontSize: 16,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontFamily: 'NotoSansJP',
          fontSize: 14,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontFamily: 'NotoSansJP',
          fontSize: 12,
        ),
      ),
    );
  }
}