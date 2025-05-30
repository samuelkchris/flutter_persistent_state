import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'persistence_backend.dart';

/// SharedPreferences implementation of the persistence backend.
///
/// This backend uses Flutter's SharedPreferences plugin to store data
/// in the platform's native preference storage (UserDefaults on iOS,
/// SharedPreferences on Android). It provides automatic JSON serialization
/// for complex types and implements retry logic for robustness.
///
/// This backend is suitable for storing small to medium amounts of data
/// that need to persist across app sessions. For large datasets or
/// complex relational data, consider using a database backend instead.
class SharedPreferencesBackend implements PersistenceBackend {
  SharedPreferences? _prefs;
  final BackendConfiguration _config;
  bool _isInitialized = false;

  /// Create a new SharedPreferences backend with optional configuration.
  ///
  /// @param config configuration options for the backend
  SharedPreferencesBackend({
    BackendConfiguration? config,
  }) : _config = config ?? const BackendConfiguration();

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e, stackTrace) {
      throw PersistenceException(
        operation: 'initialize',
        message: 'Failed to initialize SharedPreferences',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
    _prefs = null;
  }

  /// Execute an operation with retry logic.
  ///
  /// @param operation the operation to execute
  /// @param operationName the name of the operation for error reporting
  /// @param key optional key involved in the operation
  /// @returns the result of the operation
  /// @throws PersistenceException if all retry attempts fail
  Future<T> _executeWithRetry<T>(
      Future<T> Function() operation,
      String operationName, [
        String? key,
      ]) async {
    _ensureInitialized();

    int attempts = 0;
    while (attempts < _config.maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        attempts++;
        if (attempts >= _config.maxRetries) {
          throw PersistenceException(
            operation: operationName,
            key: key,
            message: 'Operation failed after ${ _config.maxRetries} attempts',
            cause: e,
            stackTrace: stackTrace,
          );
        }

        await Future.delayed(_config.retryDelay);
      }
    }

    throw PersistenceException(
      operation: operationName,
      key: key,
      message: 'Unexpected error in retry logic',
    );
  }

  /// Ensure the backend is initialized before performing operations.
  ///
  /// @throws PersistenceException if the backend is not initialized
  void _ensureInitialized() {
    if (!_isInitialized || _prefs == null) {
      throw const PersistenceException(
        operation: 'operation',
        message: 'Backend not initialized. Call initialize() first.',
      );
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    final namespacedKey = _config.applyNamespace(key);
    await _executeWithRetry(
          () => _prefs!.setString(namespacedKey, value),
      'setString',
      key,
    );
  }

  @override
  Future<String?> getString(String key) async {
    final namespacedKey = _config.applyNamespace(key);
    return await _executeWithRetry(
          () async => _prefs!.getString(namespacedKey),
      'getString',
      key,
    );
  }

  @override
  Future<void> setInt(String key, int value) async {
    final namespacedKey = _config.applyNamespace(key);
    await _executeWithRetry(
          () => _prefs!.setInt(namespacedKey, value),
      'setInt',
      key,
    );
  }

  @override
  Future<int?> getInt(String key) async {
    final namespacedKey = _config.applyNamespace(key);
    return await _executeWithRetry(
          () async => _prefs!.getInt(namespacedKey),
      'getInt',
      key,
    );
  }

  @override
  Future<void> setDouble(String key, double value) async {
    final namespacedKey = _config.applyNamespace(key);
    await _executeWithRetry(
          () => _prefs!.setDouble(namespacedKey, value),
      'setDouble',
      key,
    );
  }

  @override
  Future<double?> getDouble(String key) async {
    final namespacedKey = _config.applyNamespace(key);
    return await _executeWithRetry(
          () async => _prefs!.getDouble(namespacedKey),
      'getDouble',
      key,
    );
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final namespacedKey = _config.applyNamespace(key);
    await _executeWithRetry(
          () => _prefs!.setBool(namespacedKey, value),
      'setBool',
      key,
    );
  }

  @override
  Future<bool?> getBool(String key) async {
    final namespacedKey = _config.applyNamespace(key);
    return await _executeWithRetry(
          () async => _prefs!.getBool(namespacedKey),
      'getBool',
      key,
    );
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    final namespacedKey = _config.applyNamespace(key);
    await _executeWithRetry(
          () => _prefs!.setStringList(namespacedKey, value),
      'setStringList',
      key,
    );
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final namespacedKey = _config.applyNamespace(key);
    return await _executeWithRetry(
          () async => _prefs!.getStringList(namespacedKey),
      'getStringList',
      key,
    );
  }

  @override
  Future<void> setJson(String key, dynamic value) async {
    try {
      final jsonString = jsonEncode(value);
      await setString(key, jsonString);
    } catch (e, stackTrace) {
      throw PersistenceException(
        operation: 'setJson',
        key: key,
        message: 'Failed to serialize value to JSON',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<dynamic> getJson(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) {
        return null;
      }
      return jsonDecode(jsonString);
    } catch (e, stackTrace) {
      throw PersistenceException(
        operation: 'getJson',
        key: key,
        message: 'Failed to deserialize JSON value',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> remove(String key) async {
    final namespacedKey = _config.applyNamespace(key);
    return await _executeWithRetry(
          () async {
        final existed = _prefs!.containsKey(namespacedKey);
        await _prefs!.remove(namespacedKey);
        return existed;
      },
      'remove',
      key,
    );
  }

  @override
  Future<void> clear() async {
    if (_config.namespace != null) {
      final keys = await getKeys();
      final futures = keys.map((key) => remove(key));
      await Future.wait(futures);
    } else {
      await _executeWithRetry(
            () => _prefs!.clear(),
        'clear',
      );
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    final namespacedKey = _config.applyNamespace(key);
    return await _executeWithRetry(
          () async => _prefs!.containsKey(namespacedKey),
      'containsKey',
      key,
    );
  }

  @override
  Future<Set<String>> getKeys() async {
    return await _executeWithRetry(
          () async {
        final allKeys = _prefs!.getKeys();
        if (_config.namespace == null) {
          return allKeys;
        }

        final namespace = '${_config.namespace}:';
        return allKeys
            .where((key) => key.startsWith(namespace))
            .map((key) => key.substring(namespace.length))
            .toSet();
      },
      'getKeys',
    );
  }
}