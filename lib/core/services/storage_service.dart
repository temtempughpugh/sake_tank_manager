import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// データの永続化を管理するサービスクラス
class StorageService {
  /// 静的シングルトンインスタンス
  static final StorageService _instance = StorageService._internal();

  /// シングルトンのファクトリコンストラクタ
  factory StorageService() => _instance;

  /// 内部コンストラクタ
  StorageService._internal();

  /// SharedPreferencesのインスタンス
  SharedPreferences? _prefs;

  /// 初期化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // =================
  // 基本的なデータ操作
  // =================

  /// 文字列データを保存
  /// - [key]: 保存キー
  /// - [value]: 保存する文字列
  Future<bool> setString(String key, String value) async {
    if (_prefs == null) await initialize();
    return _prefs!.setString(key, value);
  }

  /// 文字列データを取得
  /// - [key]: 取得キー
  /// - [defaultValue]: デフォルト値（キーが存在しない場合）
  /// - 戻り値: 保存されている文字列またはデフォルト値
  String getString(String key, {String defaultValue = ''}) {
    if (_prefs == null) return defaultValue;
    return _prefs!.getString(key) ?? defaultValue;
  }

  /// 整数データを保存
  /// - [key]: 保存キー
  /// - [value]: 保存する整数
  Future<bool> setInt(String key, int value) async {
    if (_prefs == null) await initialize();
    return _prefs!.setInt(key, value);
  }

  /// 整数データを取得
  /// - [key]: 取得キー
  /// - [defaultValue]: デフォルト値（キーが存在しない場合）
  /// - 戻り値: 保存されている整数またはデフォルト値
  int getInt(String key, {int defaultValue = 0}) {
    if (_prefs == null) return defaultValue;
    return _prefs!.getInt(key) ?? defaultValue;
  }

  /// 真偽値データを保存
  /// - [key]: 保存キー
  /// - [value]: 保存する真偽値
  Future<bool> setBool(String key, bool value) async {
    if (_prefs == null) await initialize();
    return _prefs!.setBool(key, value);
  }

  /// 真偽値データを取得
  /// - [key]: 取得キー
  /// - [defaultValue]: デフォルト値（キーが存在しない場合）
  /// - 戻り値: 保存されている真偽値またはデフォルト値
  bool getBool(String key, {bool defaultValue = false}) {
    if (_prefs == null) return defaultValue;
    return _prefs!.getBool(key) ?? defaultValue;
  }

  /// キーが存在するかを確認
  /// - [key]: 確認するキー
  /// - 戻り値: キーが存在するかどうか
  bool containsKey(String key) {
    if (_prefs == null) return false;
    return _prefs!.containsKey(key);
  }

  /// 指定したキーのデータを削除
  /// - [key]: 削除するキー
  /// - 戻り値: 削除が成功したかどうか
  Future<bool> remove(String key) async {
    if (_prefs == null) await initialize();
    return _prefs!.remove(key);
  }

  // =================
  // JSON操作
  // =================

  /// オブジェクトをJSON文字列として保存
  /// - [key]: 保存キー
  /// - [value]: 保存するオブジェクト（JSON変換可能なもの）
  /// - 戻り値: 保存が成功したかどうか
  Future<bool> setObject(String key, dynamic value) async {
    final jsonString = json.encode(value);
    return setString(key, jsonString);
  }

  /// JSON文字列をオブジェクトとして取得
  /// - [key]: 取得キー
  /// - 戻り値: JSONからデコードされたオブジェクト（存在しない場合はnull）
  dynamic getObject(String key) {
    final jsonString = getString(key);
    if (jsonString.isEmpty) return null;
    
    try {
      return json.decode(jsonString);
    } catch (e) {
      print('JSON解析エラー: $e');
      return null;
    }
  }

  // =================
  // リスト操作
  // =================

  /// オブジェクトリストを保存
  /// - [key]: 保存キー
  /// - [list]: 保存するオブジェクトリスト
  /// - [toMap]: 各オブジェクトをMap<String, dynamic>に変換する関数
  /// オブジェクトリストを保存
Future<bool> setObjectList<T>(
  String key, 
  List<T> list, 
  Map<String, dynamic> Function(T item) toMap,
) async {
  final jsonList = list.map((item) => toMap(item)).toList();
  print('保存するデータ数: ${jsonList.length}');
  return setObject(key, jsonList);
}

/// オブジェクトリストを取得
List<T> getObjectList<T>(
  String key, 
  T Function(Map<String, dynamic> map) fromMap,
) {
  final jsonList = getObject(key) as List<dynamic>?;
  if (jsonList == null) {
    print('データがロードできませんでした: $key');
    return [];
  }
  
  final result = jsonList
      .map((item) => fromMap(item as Map<String, dynamic>))
      .toList();
  print('読み込んだデータ数: ${result.length}');
  return result;
}

  // =================
  // アプリ設定
  // =================

  /// 最後に選択したタンク番号を保存
  /// - [tankNumber]: タンク番号
  Future<bool> setLastSelectedTank(String tankNumber) async {
    return setString('last_selected_tank', tankNumber);
  }

  /// 最後に選択したタンク番号を取得
  /// - 戻り値: タンク番号（保存されていない場合は空文字列）
  String getLastSelectedTank() {
    return getString('last_selected_tank');
  }

  /// 最後の入力モード（検尺⇔容量）を保存
  /// - [isUsingDipstick]: 検尺モードならtrue、容量モードならfalse
  Future<bool> setLastInputMode(bool isUsingDipstick) async {
    return setBool('is_using_dipstick', isUsingDipstick);
  }

  /// 最後の入力モード（検尺⇔容量）を取得
  /// - 戻り値: 検尺モードならtrue、容量モードならfalse
  bool getLastInputMode() {
    return getBool('is_using_dipstick', defaultValue: true);
  }
  /// 逆引きモード設定を保存
/// - [isReverseMode]: 逆引きモードかどうか
Future<bool> setReverseMode(bool isReverseMode) async {
  return setBool('is_reverse_mode', isReverseMode);
}

/// 逆引きモード設定を取得
/// - 戻り値: 逆引きモードかどうか
bool getReverseMode() {
  return getBool('is_reverse_mode', defaultValue: false);
}
}