import 'package:flutter/material.dart';

/// ホーム画面
class HomeScreen extends StatelessWidget {
  /// コンストラクタ
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日本酒タンク管理'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '機能メニュー',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  children: [
                    _buildFeatureCard(
                      context,
                      title: 'タンク早見表',
                      description: '検尺値と容量の変換',
                      icon: Icons.straighten,
                      color: Colors.blue,
                      route: '/tank-reference',
                    ),
                    _buildFeatureCard(
                      context,
                      title: '割水計算',
                      description: 'アルコール度数調整用の水量計算',
                      icon: Icons.water_drop,
                      color: Colors.teal,
                      route: '/dilution',
                    ),
                    _buildFeatureCard(
                      context,
                      title: '割水計画',
                      description: '計画一覧と完了管理',
                      icon: Icons.list_alt,
                      color: Colors.green,
                      route: '/dilution-plans',
                    ),
                    _buildFeatureCard(
                      context,
                      title: '瓶詰め管理',
                      description: '瓶詰め情報の記録と管理',
                      icon: Icons.liquor,
                      color: Colors.amber[800]!,
                      route: '/bottling',
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 機能カードウィジェットを構築
  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String route,
    bool enabled = true,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: enabled
            ? () {
                print('Navigating to: $route'); // デバッグ用
                Navigator.of(context).pushNamed(route);
              }
            : () => _showFeatureNotAvailable(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: enabled ? color : Colors.grey,
              ),
              const SizedBox(height: 16.0),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: enabled ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled ? null : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              if (!enabled) ...[
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    '開発中',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 機能が利用できない場合のメッセージを表示
  void _showFeatureNotAvailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('この機能は現在開発中です'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}