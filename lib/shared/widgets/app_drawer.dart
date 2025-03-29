import 'package:flutter/material.dart';
import '../../features/brewing/screens/brewing_record_list_screen.dart';


/// アプリケーションのドロワーメニュー
class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(context),
            _buildDrawerItem(
              context,
              title: 'ホーム',
              icon: Icons.home,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
            const Divider(),
            _buildSectionHeader(context, '基本機能'),
            _buildDrawerItem(
              context,
              title: 'タンク早見表',
              icon: Icons.straighten,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/tank-reference');
              },
            ),
            const Divider(),
            _buildSectionHeader(context, '割水関連'),
            _buildDrawerItem(
              context,
              title: '割水計算',
              icon: Icons.water_drop,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/dilution');
              },
            ),
            _buildDrawerItem(
              context,
              title: '割水計画一覧',
              icon: Icons.list_alt,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/dilution-plans');
              },
            ),
            const Divider(),
            _buildSectionHeader(context, '瓶詰め関連'),
            _buildDrawerItem(
              context,
              title: '瓶詰め管理',
              icon: Icons.liquor,
              isDisabled: false,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/bottling');
              },
            ),
            _buildDrawerItem(
              context,
              title: '瓶詰め履歴',
              icon: Icons.history,
              isDisabled: false,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/bottling-list');
              },
            ),
            const Divider(),
            _buildSectionHeader(context, '工程管理'),
            _buildDrawerItem(
              context,
              title: '検定（上槽時）',
              icon: Icons.rule,
              isDisabled: true,
              onTap: () {
                Navigator.of(context).pop();
                _showDevelopmentSnackBar(context);
              },
            ),
            _buildDrawerItem(
              context,
              title: 'ろ過',
              icon: Icons.filter_alt,
              isDisabled: true,
              onTap: () {
                Navigator.of(context).pop();
                _showDevelopmentSnackBar(context);
              },
            ),
            _buildDrawerItem(
              context,
              title: '火入れ',
              icon: Icons.local_fire_department,
              isDisabled: true,
              onTap: () {
                Navigator.of(context).pop();
                _showDevelopmentSnackBar(context);
              },
            ),
            _buildDrawerItem(
              context,
              title: '蔵出し',
              icon: Icons.inventory,
              isDisabled: true,
              onTap: () {
                Navigator.of(context).pop();
                _showDevelopmentSnackBar(context);
              },
            ),
            const Divider(),
            _buildSectionHeader(context, 'その他'),
            _buildDrawerItem(
              context,
              title: '記帳サポート',
              icon: Icons.book,
              isDisabled: false,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/brewing-records');
              },
            ),
            _buildDrawerItem(
              context,
              title: '設定',
              icon: Icons.settings,
              isDisabled: true,
              onTap: () {
                Navigator.of(context).pop();
                _showDevelopmentSnackBar(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ドロワーヘッダーを構築
  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.water_drop,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '日本酒タンク管理',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          Text(
            'メニュー',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }

  /// セクションヘッダーを構築
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// ドロワー項目の構築
  Widget _buildDrawerItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDisabled ? Colors.grey : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDisabled ? Colors.grey : null,
        ),
      ),
      trailing: isDisabled
          ? Container(
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            )
          : null,
      onTap: isDisabled ? null : onTap,
    );
  }

  /// 開発中のSnackBarを表示
  void _showDevelopmentSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('この機能は現在開発中です'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}