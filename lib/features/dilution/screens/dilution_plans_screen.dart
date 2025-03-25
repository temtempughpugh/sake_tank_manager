import 'package:flutter/material.dart';

/// 割水計画一覧画面
class DilutionPlansScreen extends StatelessWidget {
  /// コンストラクタ
  const DilutionPlansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('割水計画'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.list_alt,
                  size: 72,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  '工事中',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                const Text(
                  '割水計画機能は現在開発中です。\n近日中に実装予定です。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ホームに戻る'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}