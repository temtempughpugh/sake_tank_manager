import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/tank_selector.dart';
import '../../../shared/widgets/measurement_input.dart';
import '../../../shared/widgets/result_card.dart';
import '../../../shared/widgets/approximation_chips.dart';
import '../controllers/tank_reference_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';

/// タンク早見表画面
class TankReferenceScreen extends StatefulWidget {
  /// コンストラクタ
  const TankReferenceScreen({Key? key}) : super(key: key);

  @override
  State<TankReferenceScreen> createState() => _TankReferenceScreenState();
}

class _TankReferenceScreenState extends State<TankReferenceScreen> with SingleTickerProviderStateMixin {
  /// タブコントローラー
  late TabController _tabController;
  
  /// コントローラー
  late TankReferenceController _controller;
  
  /// 検尺入力コントローラー
  final TextEditingController _dipstickController = TextEditingController();
  
  /// 容量入力コントローラー
  final TextEditingController _volumeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // タブコントローラーの初期化
    _tabController = TabController(length: 2, vsync: this);
    
    // コントローラーの初期化
    _controller = TankReferenceController();
    
    // データの読み込み
    _controller.loadInitialData().then((_) {
      // 前回選択されていたタンクがあれば復元
      final lastTank = _controller.lastSelectedTank;
      if (lastTank != null && lastTank.isNotEmpty) {
        _controller.selectTank(lastTank);
      }
    });
    
    // タブコントローラーのリスナー設定
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _controller.setDipstickMode(_tabController.index == 0);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dipstickController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('タンク早見表'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '検尺 → 容量'),
              Tab(text: '容量 → 検尺'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            // 物理スクロールを無効化してマウストラッカーエラーを回避
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDipstickToVolumeTab(),
              _buildVolumeToDipstickTab(),
            ],
          ),
        ),
      ),
    );
  }

  /// 検尺→容量タブの構築
  Widget _buildDipstickToVolumeTab() {
    return Consumer<TankReferenceController>(
      builder: (context, controller, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTankSelector(controller),
              const SizedBox(height: 16.0),
              _buildDipstickInput(controller),
              const SizedBox(height: 16.0),
              _buildCalculateButton(
                controller,
                isEnabled: controller.selectedTank != null && _dipstickController.text.isNotEmpty,
                onPressed: () => _calculateDipstickToVolume(controller),
              ),
              const SizedBox(height: 16.0),
              _buildResult(controller),
              if (controller.result != null && controller.approximationPairs.isNotEmpty) ...[
  const SizedBox(height: 16.0),
  _buildApproximationChips(controller),
]
            ],
          ),
        );
      },
    );
  }

  /// 容量→検尺タブの構築
  Widget _buildVolumeToDipstickTab() {
    return Consumer<TankReferenceController>(
      builder: (context, controller, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTankSelector(controller),
              const SizedBox(height: 16.0),
              _buildVolumeInput(controller),
              const SizedBox(height: 16.0),
              _buildCalculateButton(
                controller,
                isEnabled: controller.selectedTank != null && _volumeController.text.isNotEmpty,
                onPressed: () => _calculateVolumeToDipstick(controller),
              ),
              const SizedBox(height: 16.0),
              _buildResult(controller),
              if (controller.result != null && !controller.result!.isExactMatch && controller.approximationPairs.isNotEmpty) ...[
                const SizedBox(height: 16.0),
                _buildApproximationChips(controller),
              ],
            ],
          ),
        );
      },
    );
  }

  /// タンク選択ウィジェットの構築
  Widget _buildTankSelector(TankReferenceController controller) {
    return TankSelector(
      selectedTankNumber: controller.selectedTank,
      onTankSelected: (tankNumber) {
        controller.selectTank(tankNumber);
      },
    );
  }

  /// 検尺入力フィールドの構築
  Widget _buildDipstickInput(TankReferenceController controller) {
    // 選択されたタンク情報
    final tank = controller.selectedTankInfo;
    String? hintText;
    
    if (tank != null) {
      // タンクの検尺範囲を反映したヒント
      hintText = '${tank.minDipstick.toInt()} ~ ${tank.maxDipstick.toInt()} mm';
    } else {
      hintText = 'タンクを選択してください';
    }

    return MeasurementInput.dipstick(
      controller: _dipstickController,
      hint: hintText,
      validator: (value) {
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
      },
      onSubmitted: (_) {
        if (controller.selectedTank != null && _dipstickController.text.isNotEmpty) {
          _calculateDipstickToVolume(controller);
        }
      },
    );
  }

  /// 容量入力フィールドの構築
  Widget _buildVolumeInput(TankReferenceController controller) {
    // 選択されたタンク情報
    final tank = controller.selectedTankInfo;
    String? hintText;
    
    if (tank != null) {
      // タンクの容量範囲を反映したヒント
      hintText = '${tank.minVolume.toStringAsFixed(1)} ~ ${tank.maxVolume.toStringAsFixed(1)} L';
    } else {
      hintText = 'タンクを選択してください';
    }

    return MeasurementInput.volume(
      controller: _volumeController,
      hint: hintText,
      validator: (value) {
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
      },
      onSubmitted: (_) {
        if (controller.selectedTank != null && _volumeController.text.isNotEmpty) {
          _calculateVolumeToDipstick(controller);
        }
      },
    );
  }

  /// 計算ボタンの構築
  Widget _buildCalculateButton(
    TankReferenceController controller, {
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: const Icon(Icons.calculate),
      label: const Text('計算する'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }

  /// 結果表示ウィジェットの構築
  Widget _buildResult(TankReferenceController controller) {
    if (controller.hasError) {
      return ResultCard.error(
        title: '計算結果',
        errorMessage: controller.errorMessage ?? 'エラーが発生しました',
      );
    }

    if (controller.result == null) {
      return const SizedBox.shrink();
    }

    // 現在のモード
    final bool isDipstickMode = controller.isDipstickMode;

    // 結果
    final result = controller.result!;
    
    // 結果出力文字列
    final String resultText = isDipstickMode
        ? Formatters.volume(result.volume)
        : Formatters.dipstick(result.dipstick);
    
    // 説明文
    final String description = isDipstickMode
        ? '検尺値: ${Formatters.dipstick(result.dipstick)}'
        : '容量: ${Formatters.volume(result.volume)}';

    final String message = result.isExactMatch
        ? '完全一致するデータが見つかりました。\n$description'
        : '一致するデータがありません。\n近似値を選択してください。\n$description';

    return ResultCard(
      title: '計算結果',
      resultText: resultText,
      description: message,
      icon: isDipstickMode ? Icons.water_drop_outlined : Icons.straighten,
    );
  }

  /// 近似値チップウィジェットの構築
  Widget _buildApproximationChips(TankReferenceController controller) {
    return ApproximationChips(
      approximations: controller.approximationPairs,
      isDipstickMode: controller.isDipstickMode,
      onSelected: (pair) {
        if (controller.isDipstickMode) {
          _dipstickController.text = pair.data.dipstick.toStringAsFixed(0);
          _calculateDipstickToVolume(controller);
        } else {
          _volumeController.text = pair.data.volume.toStringAsFixed(1);
          _calculateVolumeToDipstick(controller);
        }
      },
    );
  }

  /// 検尺→容量の計算を実行
  void _calculateDipstickToVolume(TankReferenceController controller) {
    final dipstickText = _dipstickController.text;
    
    // 値のバリデーション
    if (dipstickText.isEmpty) {
      return;
    }
    
    // 文字列→数値変換
    final dipstick = double.tryParse(dipstickText);
    if (dipstick == null) {
      return;
    }
    
    // 計算実行
    controller.calculateDipstickToVolume(dipstick);
  }

  /// 容量→検尺の計算を実行
  void _calculateVolumeToDipstick(TankReferenceController controller) {
    final volumeText = _volumeController.text;
    
    // 値のバリデーション
    if (volumeText.isEmpty) {
      return;
    }
    
    // 文字列→数値変換
    final volume = double.tryParse(volumeText);
    if (volume == null) {
      return;
    }
    
    // 計算実行
    controller.calculateVolumeToDipstick(volume);
  }
}