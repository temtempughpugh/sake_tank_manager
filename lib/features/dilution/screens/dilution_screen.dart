import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/tank_selector.dart';
import '../../../shared/widgets/measurement_input.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/result_card.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/validators.dart';
import '../controllers/dilution_controller.dart';
import '../models/dilution_plan.dart';
import '../../../shared/widgets/compact_approximation_chips.dart';

/// 割水計算画面
class DilutionScreen extends StatefulWidget {
  /// 編集対象の割水計画（編集モードの場合）
  final DilutionPlan? plan;

  /// コンストラクタ
  const DilutionScreen({Key? key, this.plan}) : super(key: key);

  @override
  State<DilutionScreen> createState() => _DilutionScreenState();
}

class _DilutionScreenState extends State<DilutionScreen> {
  /// Scaffoldキー (ドロワー表示用)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  /// コントローラー
  late DilutionController _controller;
  
  /// 入力フォームのキー
  final _formKey = GlobalKey<FormState>();
  
  /// 検尺入力コントローラー
  final TextEditingController _dipstickController = TextEditingController();
  
  /// 容量入力コントローラー
  final TextEditingController _volumeController = TextEditingController();
  
  /// 初期アルコール度数コントローラー
  final TextEditingController _initialAlcoholController = TextEditingController();
  
  /// 目標アルコール度数コントローラー
  final TextEditingController _targetAlcoholController = TextEditingController();
  
  /// 酒名コントローラー
  final TextEditingController _sakeNameController = TextEditingController();
  
  /// 担当者コントローラー
  final TextEditingController _personInChargeController = TextEditingController();

  /// 最終値が確定しているかどうか
  bool _isFinalValueConfirmed = false;

  @override
  void initState() {
    super.initState();
    
    // コントローラーの初期化
    _controller = DilutionController();
    
    // データの読み込み
    _controller.loadInitialData().then((_) {
      // 編集モードの場合、計画のデータをロード
      if (widget.plan != null) {
        _loadPlanData(widget.plan!);
      } else {
        // 前回選択されていたタンクがあれば復元
        final lastTank = _controller.lastSelectedTank;
        if (lastTank != null && lastTank.isNotEmpty) {
          _controller.selectTank(lastTank);
        }
      }
    });
    
    // リスナーの設定
    _dipstickController.addListener(_onDipstickChanged);
    _volumeController.addListener(_onVolumeChanged);
  }

  /// 計画データを読み込んで画面に反映
  void _loadPlanData(DilutionPlan plan) {
    // 編集モードを設定
    _controller.setEditMode(plan);
    
    // 結果を取得
    final result = plan.result;
    
    // タンク番号を設定
    _controller.selectTank(result.tankNumber);
    
    // 検尺/容量モードを設定（デフォルトは検尺モード）
    _controller.setUsingDipstick(true);
    
    // 検尺値と容量を設定
    _dipstickController.text = result.initialDipstick.toString();
    _volumeController.text = result.initialVolume.toString();
    
    // アルコール度数を設定
    _initialAlcoholController.text = result.initialAlcoholPercentage.toString();
    _targetAlcoholController.text = result.targetAlcoholPercentage.toString();
    
    // 酒名と担当者を設定
    if (result.sakeName != null) {
      _sakeNameController.text = result.sakeName!;
    }
    if (result.personInCharge != null) {
      _personInChargeController.text = result.personInCharge!;
    }
    
    // 初期測定結果を更新
    _controller.updateMeasurementFromDipstick(result.initialDipstick);
    
    // 計算を実行
    _calculateDilution(_controller);
    
    // 最終値を確定済みとする
    _isFinalValueConfirmed = true;
  }

  @override
  void dispose() {
    // リスナーの解除
    _dipstickController.removeListener(_onDipstickChanged);
    _volumeController.removeListener(_onVolumeChanged);
    
    // コントローラーの破棄
    _dipstickController.dispose();
    _volumeController.dispose();
    _initialAlcoholController.dispose();
    _targetAlcoholController.dispose();
    _sakeNameController.dispose();
    _personInChargeController.dispose();
    
    super.dispose();
  }

  /// 検尺値が変更された時の処理
  void _onDipstickChanged() {
    if (_controller.isDipstickMode && _dipstickController.text.isNotEmpty) {
      final dipstick = double.tryParse(_dipstickController.text);
      if (dipstick != null) {
        _controller.updateMeasurementFromDipstick(dipstick);
        _isFinalValueConfirmed = false; // 入力変更で確定を解除
      }
    }
    if (_controller.result != null) {
      _controller.clearResult();
      _isFinalValueConfirmed = false;
    }
  }

  void _onVolumeChanged() {
    if (!_controller.isDipstickMode && _volumeController.text.isNotEmpty) {
      final volume = double.tryParse(_volumeController.text);
      if (volume != null) {
        _controller.updateMeasurementFromVolume(volume);
        _isFinalValueConfirmed = false; // 入力変更で確定を解除
      }
    }
    if (_controller.result != null) {
      _controller.clearResult();
      _isFinalValueConfirmed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DilutionController>(
        builder: (context, controller, child) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(controller.isEditMode ? '割水計画編集' : '割水計算'),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTankSelector(controller),
                      const SizedBox(height: 16.0),
                      _buildInputModeSelector(controller),
                      const SizedBox(height: 16.0),
                      _buildCurrentStateCard(controller),
                      const SizedBox(height: 16.0),
                      _buildAlcoholInputCard(controller),
                      const SizedBox(height: 16.0),
                      _buildAdditionalInfoCard(controller),
                      const SizedBox(height: 24.0),
                      _buildCalculateButton(controller),
                      if (controller.result != null) ...[
                        const SizedBox(height: 24.0),
                        _buildResultSection(controller),
                      ],
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

  /// タンク選択ウィジェットを構築
  Widget _buildTankSelector(DilutionController controller) {
    return TankSelector(
      selectedTankNumber: controller.selectedTank,
      onTankSelected: (tankNumber) {
        controller.selectTank(tankNumber);
        
        // 入力値をクリア
        _dipstickController.text = '';
        _volumeController.text = '';
      },
    );
  }

  /// 入力モード選択ウィジェットを構築
  Widget _buildInputModeSelector(DilutionController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '入力方法',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('検尺から計算'),
                    value: true,
                    groupValue: controller.isUsingDipstick,
                    onChanged: (value) {
                      if (value != null) {
                        controller.setUsingDipstick(value);
                        
                        // 入力値をクリア
                        _dipstickController.text = '';
                        _volumeController.text = '';
                      }
                    },
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('容量から計算'),
                    value: false,
                    groupValue: controller.isUsingDipstick,
                    onChanged: (value) {
                      if (value != null) {
                        controller.setUsingDipstick(value);
                        
                        // 入力値をクリア
                        _dipstickController.text = '';
                        _volumeController.text = '';
                      }
                    },
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 現在の状態入力カードを構築
  Widget _buildCurrentStateCard(DilutionController controller) {
    final tank = controller.selectedTankInfo;
    
    // 選択されたタンクに基づいてヒントテキストを設定
    String? dipstickHint;
    String? volumeHint;
    
    if (tank != null) {
      dipstickHint = '${tank.minDipstick.toInt()} ~ ${tank.maxDipstick.toInt()} mm';
      volumeHint = '${tank.minVolume.toStringAsFixed(1)} ~ ${tank.maxVolume.toStringAsFixed(1)} L';
    } else {
      dipstickHint = 'タンクを選択してください';
      volumeHint = 'タンクを選択してください';
    }
    
    // 測定結果から容量を表示（検尺入力モードの場合）
    if (controller.isDipstickMode && controller.measurementResult != null && 
        !controller.measurementResult!.hasError) {
      _volumeController.text = controller.measurementResult!.volume.toString();
    }
    
    // 測定結果から検尺を表示（容量入力モードの場合）
    if (!controller.isDipstickMode && controller.measurementResult != null && 
        !controller.measurementResult!.hasError) {
      _dipstickController.text = controller.measurementResult!.dipstick.toString();
    }

    return SectionCard(
      title: '現在の状態',
      icon: Icons.water_drop_outlined,
      child: Column(
        children: [
          // 検尺入力フィールド
          MeasurementInput.dipstick(
            controller: _dipstickController,
            hint: dipstickHint,
            readOnly: !controller.isDipstickMode,
            validator: (value) {
              if (controller.isDipstickMode) {
                if (value == null || value.isEmpty) {
                  return '検尺値を入力してください';
                }
                
                if (tank != null) {
                  final dipstick = double.tryParse(value);
                  if (dipstick != null && dipstick > tank.maxDipstick) {
                    return 'タンクの最大検尺値(${tank.maxDipstick.toInt()}mm)を超えています';
                  }
                  if (dipstick != null && dipstick < tank.minDipstick) {
                    return 'タンクの最小検尺値(${tank.minDipstick.toInt()}mm)未満です';
                  }
                }
                
                return Validators.compose(
                  value,
                  [
                    Validators.numeric,
                    (v) => Validators.range(v, min: 0.0),
                  ],
                );
              }
              return null;
            },
            onChanged: (value) {
              if (controller.isDipstickMode && value.isNotEmpty) {
                final dipstick = double.tryParse(value);
                if (dipstick != null) {
                  controller.updateMeasurementFromDipstick(dipstick);
                }
              }
            },
          ),
          const SizedBox(height: 16.0),
          // 容量入力フィールド
          MeasurementInput.volume(
            controller: _volumeController,
            hint: volumeHint,
            readOnly: controller.isDipstickMode,
            validator: (value) {
              if (!controller.isDipstickMode) {
                if (value == null || value.isEmpty) {
                  return '容量を入力してください';
                }
                
                if (tank != null) {
                  final volume = double.tryParse(value);
                  if (volume != null && volume > tank.maxVolume) {
                    return 'タンクの最大容量(${tank.maxVolume.toStringAsFixed(1)}L)を超えています';
                  }
                  if (volume != null && volume < tank.minVolume) {
                    return 'タンクの最小容量(${tank.minVolume.toStringAsFixed(1)}L)未満です';
                  }
                }
                
                return Validators.compose(
                  value,
                  [
                    Validators.numeric,
                    (v) => Validators.range(v, min: 0.0),
                  ],
                );
              }
              return null;
            },
            onChanged: (value) {
              if (!controller.isDipstickMode && value.isNotEmpty) {
                final volume = double.tryParse(value);
                if (volume != null) {
                  controller.updateMeasurementFromVolume(volume);
                }
              }
            },
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 16.0),
            Text(
              controller.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          
          // 近似値候補の表示を追加（コンパクト版）
          if (controller.inputApproximationPairs.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            const Divider(height: 1),
            const SizedBox(height: 6.0),
            CompactApproximationChips(
              approximations: controller.inputApproximationPairs,
              isDipstickMode: controller.isDipstickMode,
              onSelected: (pair) {
                controller.updateFromInputApproximation(pair);
                if (controller.isDipstickMode) {
                  _dipstickController.text = pair.data.dipstick.toString();
                } else {
                  _volumeController.text = pair.data.volume.toString();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  /// アルコール入力カードを構築
  Widget _buildAlcoholInputCard(DilutionController controller) {
    return SectionCard(
      title: 'アルコール度数',
      icon: Icons.percent,
      child: Column(
        children: [
          // 初期アルコール度数入力フィールド
          MeasurementInput.alcohol(
            controller: _initialAlcoholController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '初期アルコール度数を入力してください';
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
          ),
          const SizedBox(height: 16.0),
          // 目標アルコール度数入力フィールド
          MeasurementInput.alcohol(
            controller: _targetAlcoholController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '目標アルコール度数を入力してください';
              }
              
              final targetAlcohol = double.tryParse(value);
              if (targetAlcohol == null || targetAlcohol <= 0) {
                return 'アルコール度数は0より大きい値にしてください';
              }
              
              if (targetAlcohol > 100) {
                return 'アルコール度数は100%以下にしてください';
              }
              
              final initialAlcohol = double.tryParse(_initialAlcoholController.text);
              if (initialAlcohol != null && targetAlcohol >= initialAlcohol) {
                return '目標アルコール度数は初期アルコール度数より小さい値にしてください';
              }
              
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// 追加情報入力カードを構築
  Widget _buildAdditionalInfoCard(DilutionController controller) {
    return SectionCard(
      title: '追加情報（任意）',
      icon: Icons.info_outline,
      child: Column(
        children: [
          // 酒名入力フィールド
          TextFormField(
            controller: _sakeNameController,
            decoration: const InputDecoration(
              labelText: '酒名',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16.0),
          // 担当者入力フィールド
          TextFormField(
            controller: _personInChargeController,
            decoration: const InputDecoration(
              labelText: '担当者',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  /// 計算ボタンを構築
  Widget _buildCalculateButton(DilutionController controller) {
    return ElevatedButton.icon(
      onPressed: () => _calculateDilution(controller),
      icon: const Icon(Icons.calculate),
      label: const Text('計算する'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }

  /// 結果セクションを構築
  Widget _buildResultSection(DilutionController controller) {
    final result = controller.result!;
    
    if (result.hasError) {
      return ResultCard.error(
        title: '計算結果',
        errorMessage: result.errorMessage ?? 'エラーが発生しました',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: '計算結果',
          icon: Icons.check_circle_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResultCard(
                title: '追加水量',
                resultText: '${result.waterAmount.toStringAsFixed(2)} L',
                description: '${result.initialVolume.toStringAsFixed(2)} L から ${result.finalVolume.toStringAsFixed(2)} L に増加',
                icon: Icons.water_drop,
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              const SizedBox(height: 12.0),
              ResultCard(
                title: '最終アルコール度数',
                resultText: '${result.finalAlcoholPercentage.toStringAsFixed(2)} %',
                description: '初期: ${result.initialAlcoholPercentage.toStringAsFixed(2)} % → 目標: ${result.targetAlcoholPercentage.toStringAsFixed(2)} %',
                icon: Icons.percent,
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              const SizedBox(height: 12.0),
              ResultCard(
                title: '最終検尺値',
                resultText: '${result.finalDipstick.toStringAsFixed(1)} mm',
                description: '初期: ${result.initialDipstick.toStringAsFixed(1)} mm',
                icon: Icons.straighten,
                color: Theme.of(context).colorScheme.tertiaryContainer,
              ),
            ],
          ),
        ),
        // ここを修正：常に近似値選択UIを表示する
        if (controller.approximationPairs.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          SectionCard(
            title: '最終容量の近似値選択',
            icon: Icons.tune,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最終容量を調整するには、近似値から選択してください：',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children: controller.approximationPairs.map((pair) {
                    final isSelected = controller.result?.finalVolume == pair.data.volume;
                    return ChoiceChip(
                      label: Text('${pair.data.volume.toStringAsFixed(0)} L'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          controller.updateFromApproximateVolume(pair.data.volume);
                          setState(() {
                            // 選択した値が確定したフラグを立てる
                            _isFinalValueConfirmed = true;
                          });
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                          width: isSelected ? 2.0 : 1.0, // 選択時に縁取りを太く
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20.0),
        ElevatedButton.icon(
          onPressed: () {
            // 計算結果から保存
            _saveDilutionPlan(controller);
          },
          icon: const Icon(Icons.save),
          label: Text(controller.isEditMode ? '計画を更新' : '割水計画として保存'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 8.0),
        TextButton.icon(
          onPressed: () {
            controller.clearResult();
            setState(() { 
              _isFinalValueConfirmed = false;
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('クリア'),
        ),
      ],
    );
  }

  /// 割水計算を実行
  void _calculateDilution(DilutionController controller) {
    // フォームのバリデーション
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 選択されたタンクの確認
    if (controller.selectedTank == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        'タンクを選択してください',
      );
      return;
    }

    try {
      // 入力値の取得
      double initialValue;
      if (controller.isDipstickMode) {
        initialValue = double.parse(_dipstickController.text);
      } else {
        initialValue = double.parse(_volumeController.text);
      }
      
      final initialAlcohol = double.parse(_initialAlcoholController.text);
      final targetAlcohol = double.parse(_targetAlcoholController.text);
      
      final sakeName = _sakeNameController.text.isNotEmpty 
          ? _sakeNameController.text 
          : null;
          
      final personInCharge = _personInChargeController.text.isNotEmpty 
          ? _personInChargeController.text 
          : null;

      // 割水計算の実行
      controller.calculateDilution(
        initialValue: initialValue,
        initialAlcoholPercentage: initialAlcohol,
        targetAlcoholPercentage: targetAlcohol,
        sakeName: sakeName,
        personInCharge: personInCharge,
      );

    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        '計算中にエラーが発生しました: $e',
      );
    }
  }

  /// 割水計画を保存
  Future<void> _saveDilutionPlan(DilutionController controller) async {
    if (controller.result == null || controller.result!.hasError) {
      ErrorHandler.showErrorSnackBar(
        context,
        '有効な計算結果がありません',
      );
      return;
    }

    // 近似値がある場合のみ確定が必要
    if (!_isFinalValueConfirmed && controller.approximationPairs.isNotEmpty) {
      ErrorHandler.showErrorSnackBar(
        context,
        '最終容量の近似値を選択して確定してください',
      );
      return;
    }

    try {
      await controller.saveDilutionPlan(widget.plan?.id);
      
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          controller.isEditMode ? '割水計画を更新しました' : '割水計画を保存しました',
        );
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