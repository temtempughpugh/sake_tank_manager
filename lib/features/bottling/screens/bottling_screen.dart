import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/utils/error_handler.dart';
import '../controllers/bottling_controller.dart';
import '../models/bottling_info.dart';
import '../controllers/bottling_manager.dart';


/// 瓶詰め管理画面
class BottlingScreen extends StatefulWidget {
  /// 編集する瓶詰め情報（オプション）
  final BottlingInfo? bottlingInfo;

  /// コンストラクタ
  const BottlingScreen({
    Key? key,
    this.bottlingInfo,
  }) : super(key: key);

  @override
  State<BottlingScreen> createState() => _BottlingScreenState();
}

class _BottlingScreenState extends State<BottlingScreen> {
  /// Scaffoldキー (ドロワー表示用)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// コントローラー
  late BottlingController _controller;
  
  /// 入力フォームのキー
  final _formKey = GlobalKey<FormState>();
  
  /// 酒名コントローラー
  final TextEditingController _sakeNameController = TextEditingController();
  
  /// アルコール度数コントローラー
  final TextEditingController _alcoholController = TextEditingController();
  
  /// 品温コントローラー
  final TextEditingController _temperatureController = TextEditingController();
  
  /// 詰残量コントローラー
  final TextEditingController _remainingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // コントローラーの初期化
  _controller = BottlingController(
  bottlingManager: Provider.of<BottlingManager>(context, listen: false)
);
    
    // 編集モードかどうかをチェック
    if (widget.bottlingInfo != null) {
      _controller.setUpdateMode(widget.bottlingInfo!);
      
      // テキストフィールドに値を設定
      _sakeNameController.text = widget.bottlingInfo!.sakeName;
      _alcoholController.text = widget.bottlingInfo!.alcoholPercentage.toString();
      
      if (widget.bottlingInfo!.temperature != null) {
        _temperatureController.text = widget.bottlingInfo!.temperature.toString();
      }
      
      _remainingController.text = widget.bottlingInfo!.remainingAmount.toString();
    }
    
    // リスナーの追加
    _sakeNameController.addListener(_updateSakeName);
    _alcoholController.addListener(_updateAlcoholPercentage);
    _temperatureController.addListener(_updateTemperature);
    _remainingController.addListener(_updateRemainingAmount);
  }

  @override
  void dispose() {
    // リスナーの削除
    _sakeNameController.removeListener(_updateSakeName);
    _alcoholController.removeListener(_updateAlcoholPercentage);
    _temperatureController.removeListener(_updateTemperature);
    _remainingController.removeListener(_updateRemainingAmount);
    
    // コントローラーの破棄
    _sakeNameController.dispose();
    _alcoholController.dispose();
    _temperatureController.dispose();
    _remainingController.dispose();
    
    super.dispose();
  }

  /// 酒名を更新
  void _updateSakeName() {
    _controller.setSakeName(_sakeNameController.text);
  }

  /// アルコール度数を更新
  void _updateAlcoholPercentage() {
    final text = _alcoholController.text;
    if (text.isNotEmpty) {
      final value = double.tryParse(text);
      if (value != null) {
        _controller.setAlcoholPercentage(value);
      }
    }
  }

  /// 品温を更新
  void _updateTemperature() {
    final text = _temperatureController.text;
    if (text.isNotEmpty) {
      final value = double.tryParse(text);
      _controller.setTemperature(value);
    } else {
      _controller.setTemperature(null);
    }
  }

  /// 詰残量を更新
  void _updateRemainingAmount() {
    final text = _remainingController.text;
    if (text.isNotEmpty) {
      final value = double.tryParse(text);
      if (value != null) {
        _controller.setRemainingAmount(value);
      }
    } else {
      _controller.setRemainingAmount(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<BottlingController>(
        builder: (context, controller, child) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(controller.isUpdateMode ? '瓶詰め情報編集' : '新規瓶詰め'),
              actions: [
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
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBasicInfoCard(controller),
                      const SizedBox(height: 16.0),
                      _buildBottleEntriesCard(controller),
                      const SizedBox(height: 16.0),
                      _buildResultCard(controller),
                      const SizedBox(height: 24.0),
                      _buildSaveButton(controller),
                      const SizedBox(height: 8.0),
                      if (controller.isUpdateMode)
                        _buildCancelButton(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 基本情報カードを構築
  Widget _buildBasicInfoCard(BottlingController controller) {
    return SectionCard(
      title: '基本情報',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付選択
          InkWell(
            onTap: () => _selectDate(context, controller),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '日付',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                DateFormat('yyyy/MM/dd').format(controller.date),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          // 酒名入力
          TextFormField(
            controller: _sakeNameController,
            decoration: const InputDecoration(
              labelText: '酒名',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '酒名を入力してください';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16.0),
          // アルコール度数入力
          TextFormField(
            controller: _alcoholController,
            decoration: const InputDecoration(
              labelText: 'アルコール度数',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              suffixText: '%',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'アルコール度数を入力してください';
              }
              
              final alcohol = double.tryParse(value);
              if (alcohol == null || alcohol <= 0) {
                return 'アルコール度数は0より大きい値にしてください';
              }
              
              if (alcohol > 100) {
                return 'アルコール度数は100%以下にしてください';
              }
              
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16.0),
          // 品温入力（オプション）
          TextFormField(
            controller: _temperatureController,
            decoration: const InputDecoration(
              labelText: '品温（オプション）',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              suffixText: '℃',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final temp = double.tryParse(value);
                if (temp == null) {
                  return '有効な数値を入力してください';
                }
                
                if (temp < -30 || temp > 100) {
                  return '現実的な温度範囲で入力してください';
                }
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16.0),
          // 詰残量入力
          TextFormField(
            controller: _remainingController,
            decoration: const InputDecoration(
              labelText: '詰残量（1.8L換算）',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              suffixText: '本',
              hintText: '例: 2.5',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final remaining = double.tryParse(value);
                if (remaining == null) {
                  return '有効な数値を入力してください';
                }
                
                if (remaining < 0) {
                  return '0以上の値を入力してください';
                }
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  /// 瓶種リストカードを構築
  Widget _buildBottleEntriesCard(BottlingController controller) {
    return SectionCard(
      title: '瓶種一覧',
      icon: Icons.liquor,
      action: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => _showAddBottleEntryDialog(context, controller),
        tooltip: '瓶種追加',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.bottleEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  '瓶種が追加されていません',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                // ヘッダー行
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '瓶種',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'ケース',
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'バラ',
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '本数',
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // アクションボタン用のスペース
                    ],
                  ),
                ),
                const Divider(),
                // 瓶種リスト
                ...List.generate(
                  controller.bottleEntries.length,
                  (index) => _buildBottleEntryItem(controller, index),
                ),
              ],
            ),
          const SizedBox(height: 16.0),
          // 瓶種追加ボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddBottleEntryDialog(context, controller),
              icon: const Icon(Icons.add),
              label: const Text('瓶種を追加'),
            ),
          ),
        ],
      ),
    );
  }

  /// 瓶種アイテムを構築
  Widget _buildBottleEntryItem(BottlingController controller, int index) {
    final entry = controller.bottleEntries[index];
    final bottleType = entry.bottleType;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bottleType.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${bottleType.capacity}ml × ${bottleType.bottlesPerCase}本/ケース',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${entry.cases}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${entry.bottles}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${entry.totalBottles}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => controller.removeBottleEntry(index),
              tooltip: '削除',
            ),
          ),
        ],
      ),
    );
  }

  /// 結果カードを構築
  Widget _buildResultCard(BottlingController controller) {
  return SectionCard(
    title: '計算結果',
    icon: Icons.calculate,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 集計結果（既存部分）
        _buildResultItem(
          context,
          label: '総本数',
          value: '${controller.totalBottles} 本',
        ),
        _buildResultItem(
          context,
          label: '瓶詰め総量',
          value: '${controller.totalVolume.toStringAsFixed(1)} L',
        ),
        _buildResultItem(
          context,
          label: '詰残量',
          value: '${controller.remainingAmount} × 1.8L = ${(controller.remainingAmount * 1.8).toStringAsFixed(1)} L',
        ),
        _buildResultItem(
          context,
          label: '合計容量',
          value: '${controller.totalVolumeWithRemaining.toStringAsFixed(1)} L',
          isHighlighted: true,
        ),
        const Divider(),
        
        // 純アルコール計算（全体）
        _buildResultItem(
          context,
          label: '純アルコール量',
          value: '${controller.pureAlcoholAmount.toStringAsFixed(1)} L',
          isHighlighted: true,
        ),
        
        // ここから追加：詰め残の純アルコール量
        _buildResultItem(
          context,
          label: '詰残純アルコール量',
          value: '${((controller.remainingAmount * 1.8) * controller.alcoholPercentage / 100).toStringAsFixed(1)} L',
        ),
        
        // 瓶種ごとの純アルコール量を表示（新規追加）
        const SizedBox(height: 16.0),
        Text(
          '瓶種ごとの純アルコール量',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8.0),
        
        // 瓶種ごとの純アルコール量を一覧表示
        ...controller.bottleEntries.map((entry) {
          final pureAlcohol = entry.totalVolume * controller.alcoholPercentage / 100;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('${entry.bottleType.name} (${entry.bottleType.capacity}ml)'),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${pureAlcohol.toStringAsFixed(1)} L',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    ),
  );
}

  /// 結果アイテムを構築
  Widget _buildResultItem(
    BuildContext context, {
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: isHighlighted
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: isHighlighted
                  ? TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 保存ボタンを構築
  Widget _buildSaveButton(BottlingController controller) {
    return ElevatedButton.icon(
      onPressed: () => _saveBottlingInfo(controller),
      icon: const Icon(Icons.save),
      label: Text(controller.isUpdateMode ? '更新' : '保存'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }

  /// キャンセルボタンを構築
  Widget _buildCancelButton() {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.cancel),
      label: const Text('キャンセル'),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }



  /// 日付選択ダイアログを表示
  Future<void> _selectDate(BuildContext context, BottlingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (picked != null && picked != controller.date) {
      controller.setDate(picked);
    }
  }

  /// 瓶種追加ダイアログを表示（修正版）
Future<void> _showAddBottleEntryDialog(
  BuildContext context, 
  BottlingController controller,
) async {
  // ダイアログが閉じられたかを追跡するフラグ
  bool isDialogActive = true;
  
  // すべてのコントローラーを事前に作成
  final casesController = TextEditingController(text: '0');
  final bottlesController = TextEditingController(text: '0');
  final customNameController = TextEditingController();
  final customCapacityController = TextEditingController();
  final customBottlesPerCaseController = TextEditingController();
  
  // コントローラーを確実に破棄する
  void disposeControllers() {
    casesController.dispose();
    bottlesController.dispose();
    customNameController.dispose();
    customCapacityController.dispose();
    customBottlesPerCaseController.dispose();
  }
  
  try {
    BottleType selectedBottleType = BottleType.standardTypes[0];
    bool isCustomBottleType = false;
    
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ダイアログがすでに閉じられていたら空のコンテナを返す
            if (!isDialogActive) return Container();
            
            return AlertDialog(
              title: const Text('瓶種追加'),
              content: Form(
                key: GlobalKey<FormState>(),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 標準瓶種 / カスタム瓶種の選択
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('標準'),
                              value: false,
                              groupValue: isCustomBottleType,
                              onChanged: (value) {
                                if (value != null && isDialogActive) {
                                  setDialogState(() {
                                    isCustomBottleType = value;
                                  });
                                }
                              },
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('カスタム'),
                              value: true,
                              groupValue: isCustomBottleType,
                              onChanged: (value) {
                                if (value != null && isDialogActive) {
                                  setDialogState(() {
                                    isCustomBottleType = value;
                                  });
                                }
                              },
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      
                      if (!isCustomBottleType) ...[
                        // 標準瓶種選択
                        DropdownButtonFormField<BottleType>(
                          decoration: const InputDecoration(
                            labelText: '瓶種',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedBottleType,
                          items: BottleType.standardTypes.map((type) {
                            return DropdownMenuItem<BottleType>(
                              value: type,
                              child: Text('${type.name} (${type.capacity}ml, ${type.bottlesPerCase}本/ケース)'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && isDialogActive) {
                              setDialogState(() {
                                selectedBottleType = value;
                              });
                            }
                          },
                        ),
                      ] else ...[
                        // カスタム瓶種入力 (引き続き同様の修正)
                        // ...
                        TextFormField(
                          controller: customNameController,
                          decoration: const InputDecoration(
                            labelText: '瓶種名',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '瓶種名を入力してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: customCapacityController,
                          decoration: const InputDecoration(
                            labelText: '容量',
                            border: OutlineInputBorder(),
                            suffixText: 'ml',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '容量を入力してください';
                            }
                            
                            final capacity = int.tryParse(value);
                            if (capacity == null || capacity <= 0) {
                              return '有効な容量を入力してください';
                            }
                            
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: customBottlesPerCaseController,
                          decoration: const InputDecoration(
                            labelText: 'ケースあたりの本数',
                            border: OutlineInputBorder(),
                            suffixText: '本/ケース',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'ケースあたりの本数を入力してください';
                            }
                            
                            final bottlesPerCase = int.tryParse(value);
                            if (bottlesPerCase == null || bottlesPerCase <= 0) {
                              return '有効な本数を入力してください';
                            }
                            
                            return null;
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 24.0),
                      const Divider(),
                      const SizedBox(height: 16.0),
                      
                      // 数量入力
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: casesController,
                              decoration: const InputDecoration(
                                labelText: 'ケース数',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'ケース数を入力してください';
                                }
                                
                                final cases = int.tryParse(value);
                                if (cases == null || cases < 0) {
                                  return '0以上の値を入力してください';
                                }
                                
                                // ケース数とバラ本数の両方が0の場合はエラー
                                final bottles = int.tryParse(bottlesController.text) ?? 0;
                                if (cases == 0 && bottles == 0) {
                                  return 'ケース数またはバラ本数を入力してください';
                                }
                                
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: TextFormField(
                              controller: bottlesController,
                              decoration: const InputDecoration(
                                labelText: 'バラ本数',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'バラ本数を入力してください';
                                }
                                
                                final bottles = int.tryParse(value);
                                if (bottles == null || bottles < 0) {
                                  return '0以上の値を入力してください';
                                }
                                
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isDialogActive = false; // フラグを更新
                    Navigator.of(context).pop();
                  },
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 瓶種の決定
                    BottleType bottleType;
                    if (isCustomBottleType) {
                      bottleType = BottleType(
                        name: customNameController.text,
                        capacity: int.parse(customCapacityController.text),
                        bottlesPerCase: int.parse(customBottlesPerCaseController.text),
                      );
                    } else {
                      bottleType = selectedBottleType;
                    }
                    
                    // 数量の取得
                    final cases = int.parse(casesController.text);
                    final bottles = int.parse(bottlesController.text);
                    
                    // フラグを更新してからコントローラーを使用
                    isDialogActive = false;
                    
                    // コントローラーに追加
                    controller.addBottleEntry(bottleType, cases, bottles);
                    
                    Navigator.of(context).pop();
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    // ダイアログがどう閉じられても確実にコントローラーを破棄
    if (isDialogActive) {
      isDialogActive = false;
    }
    disposeControllers();
  }
}

  /// 瓶詰め情報を保存
  Future<void> _saveBottlingInfo(BottlingController controller) async {
    // フォームのバリデーション
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 瓶種が追加されているかチェック
    if (controller.bottleEntries.isEmpty) {
      ErrorHandler.showErrorSnackBar(
        context,
        '少なくとも1つの瓶種を追加してください',
      );
      return;
    }

    try {
      await controller.saveBottlingInfo();
      
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          controller.isUpdateMode ? '瓶詰め情報を更新しました' : '瓶詰め情報を保存しました',
        );
        
        // 保存後に前の画面に戻る
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          '保存に失敗しました: $e',
        );
      }
    }
  }
}