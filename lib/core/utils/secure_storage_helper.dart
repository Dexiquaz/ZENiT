// No unused imports
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<String?> getString(String key) async {
    return _storage.read(key: key);
  }

  static Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<bool?> getBool(String key) async {
    final str = await getString(key);
    if (str == null) return null;
    return str.toLowerCase() == 'true';
  }

  static Future<void> setBool(String key, bool value) async {
    await setString(key, value.toString());
  }

  static Future<int?> getInt(String key) async {
    final str = await getString(key);
    if (str == null) return null;
    return int.tryParse(str);
  }

  static Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
  }

  static Future<void> remove(String key) async {
    await _storage.delete(key: key);
  }
}
