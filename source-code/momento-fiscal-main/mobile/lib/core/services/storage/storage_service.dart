import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço centralizado de storage que funciona em Web e Mobile
/// - Web: usa SharedPreferences
/// - Mobile: usa FlutterSecureStorage (mais seguro)
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Escrever um valor no storage
  Future<void> write({required String key, required String? value}) async {
    if (value == null) return;
    
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  /// Ler um valor do storage
  Future<String?> read({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  /// Deletar um valor específico
  Future<void> delete({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  /// Limpar todo o storage
  Future<void> deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }

  /// Verificar se uma chave existe
  Future<bool> containsKey({required String key}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } else {
      return await _secureStorage.containsKey(key: key);
    }
  }

  /// Ler todas as chaves (útil para debug)
  Future<Map<String, String>> readAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, String> result = {};
      for (var key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          result[key] = value;
        }
      }
      return result;
    } else {
      return await _secureStorage.readAll();
    }
  }
}

/// Instância global do storage service para compatibilidade com código existente
final storage = StorageService();

