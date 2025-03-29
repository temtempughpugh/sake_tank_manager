import 'package:flutter/material.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_handler.dart';
import '../controllers/brewing_record_service.dart';
import '../../bottling/models/bottling_info.dart';
import 'brewing_record_screen.dart';

/// 記帳サポート一覧画面
class BrewingRecordListScreen extends StatefulWidget {
  /// コンストラクタ
  const BrewingRecordListScreen({Key? key}) : super(key: key);

  @override
  State<BrewingRecordListScreen> createState() => _BrewingRecordListScreenState();
}

class _BrewingRecordListScreenState extends State<BrewingRecordListScreen> {
  /// Scaffoldキー (ドロワー表示用)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  /// 記帳サービス
  final BrewingRecordService _recordService = BrewingRecordService();
  
  /// 瓶詰め情報リスト (未記帳)
  List<BottlingInfo> _bottlingInfos = [];
  
  /// 読み込み中フラグ
  bool _isLoading = true;
  
  /// 検索キーワード
  String _searchQuery = '';
  
  /// 検索コントローラー
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBottlingInfos();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 瓶詰め情報を読み込む
  Future<void> _loadBottlingInfos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bottlingInfos = await _recordService.getUnrecordedBottlingInfos();
      
      setState(() {
        _bottlingInfos = bottlingInfos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          '瓶詰め情報の読み込みに失敗しました: $e',
        );
      }
    }
  }

  /// 検索キーワードでフィルタリングされた瓶詰め情報を取得
  List<BottlingInfo> get filteredBottlingInfos {
    if (_searchQuery.isEmpty) {
      return _bottlingInfos;
    }
    
    final lowercaseQuery = _searchQuery.toLowerCase();
    return _bottlingInfos.where((info) {
      return info.sakeName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('記帳サポート'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBottlingInfos,
            tooltip: '更新',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            tooltip: 'メニュー',
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '検索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // メインコンテンツ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBottlingInfoList(),
          ),
        ],
      ),
    );
  }

  /// 瓶詰め情報リストを構築
  Widget _buildBottlingInfoList() {
    final infos = filteredBottlingInfos;
    
    if (infos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.note_alt,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16.0),
            Text(
              _searchQuery.isEmpty 
                  ? '記帳する瓶詰め情報はありません' 
                  : '検索結果はありません',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/bottling'),
              icon: const Icon(Icons.add),
              label: const Text('新規瓶詰め'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadBottlingInfos,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: infos.length,
        itemBuilder: (context, index) {
          final bottlingInfo = infos[index];
          return _buildBottlingInfoItem(bottlingInfo);
        },
      ),
    );
  }

  /// 瓶詰め情報アイテムを構築
  Widget _buildBottlingInfoItem(BottlingInfo bottlingInfo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bottlingInfo.sakeName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(
                  Formatters.dateFormat(bottlingInfo.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.percent, size: 16),
                const SizedBox(width: 4.0),
                Text(
                  'アルコール度数: ${bottlingInfo.alcoholPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Row(
              children: [
                const Icon(Icons.water_drop, size: 16),
                const SizedBox(width: 4.0),
                Text(
                  '総量: ${bottlingInfo.totalVolumeWithRemaining.toStringAsFixed(1)}L',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _selectBottlingInfo(bottlingInfo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('選択'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 瓶詰め情報を選択して記帳画面へ遷移
  void _selectBottlingInfo(BottlingInfo bottlingInfo) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BrewingRecordScreen(bottlingInfo: bottlingInfo),
      ),
    ).then((result) {
      if (result == true) {
        // 記帳が完了したらリストを更新
        _loadBottlingInfos();
      }
    });
  }
}