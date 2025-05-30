import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_persistent_state/src/backends/persistence_backend.dart';
import 'package:flutter_persistent_state/src/backends/shared_preferences_backend.dart';


/// Reactive state manager that coordinates persistence and UI updates.
///
/// This class manages the lifecycle of persistent state, providing automatic
/// hydration from storage, reactive updates when values change, and batched
/// persistence operations for performance. It supports multiple backends
/// and provides type-safe operations for different data types.
///
/// The manager uses a publish-subscribe pattern to notify listeners of
/// state changes, enabling automatic UI updates without manual intervention.
class PersistentStateManager extends ChangeNotifier {
  static PersistentStateManager? _instance;
  static final Map<String, PersistentStateManager> _namedInstances = {};

  final PersistenceBackend _backend;
  final Map<String, dynamic> _cache = {};
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, dynamic> _defaultValues = {};
  final Set<String> _dirtyKeys = HashSet<String>();
  final Duration _batchPersistInterval;

  Timer? _batchTimer;
  bool _isInitialized = false;

  /// Create a new state manager with the specified backend.
  ///
  /// @param backend the persistence backend to use for storage operations
  /// @param batchPersistInterval how often to flush dirty values to storage
  PersistentStateManager._({
    required PersistenceBackend backend,
    Duration batchPersistInterval = const Duration(milliseconds: 500),
  })  : _backend = backend,
        _batchPersistInterval = batchPersistInterval;

  /// Get the default singleton instance of the state manager.
  ///
  /// This instance uses SharedPreferences as the default backend.
  /// For custom backends or multiple instances, use [getNamedInstance].
  ///
  /// @returns the default state manager instance
  static PersistentStateManager get instance {
    return _instance ??= PersistentStateManager._(
      backend: SharedPreferencesBackend(),
    );
  }

  /// Get a named instance of the state manager.
  ///
  /// Named instances allow you to use different backends or configurations
  /// for different parts of your application. Each named instance maintains
  /// its own state and persistence.
  ///
  /// @param name unique identifier for this instance
  /// @param backend optional custom backend (defaults to SharedPreferences)
  /// @param batchPersistInterval optional custom batch interval
  /// @returns the named state manager instance
  static PersistentStateManager getNamedInstance(
      String name, {
        PersistenceBackend? backend,
        Duration? batchPersistInterval,
      }) {
    return _namedInstances[name] ??= PersistentStateManager._(
      backend: backend ?? SharedPreferencesBackend(),
      batchPersistInterval: batchPersistInterval ?? const Duration(milliseconds: 500),
    );
  }

  /// Initialize the state manager and its backend.
  ///
  /// This method must be called before using any other functionality.
  /// It initializes the persistence backend and sets up internal state.
  ///
  /// @throws PersistenceException if backend initialization fails
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _backend.initialize();
    _isInitialized = true;
    _startBatchTimer();
  }

  /// Dispose of the state manager and clean up resources.
  ///
  /// This method should be called when the state manager is no longer needed.
  /// It flushes any pending changes, closes the backend, and cleans up timers.
  @override
  Future<void> dispose() async {
    await _flushPendingChanges();
    _batchTimer?.cancel();

    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    await _backend.close();
    _isInitialized = false;
    super.dispose();
  }

  /// Check if the manager is initialized and ready for use.
  ///
  /// @returns true if initialized, false otherwise
  bool get isInitialized => _isInitialized;

  /// Register a default value for a specific key.
  ///
  /// Default values are used when no persisted value exists for a key.
  /// This method should be called during widget initialization.
  ///
  /// @param key the storage key
  /// @param defaultValue the default value to use
  void registerDefault(String key, dynamic defaultValue) {
    _ensureInitialized();
    _defaultValues[key] = defaultValue;
  }

  /// Get a value by key with automatic type casting.
  ///
  /// This method first checks the in-memory cache, then falls back to
  /// the persistence backend if not cached. If no value exists,
  /// the registered default value is returned.
  ///
  /// @param key the storage key
  /// @returns the value, or the default value if not found
  Future<T?> getValue<T>(String key) async {
    _ensureInitialized();

    if (_cache.containsKey(key)) {
      return _cache[key] as T?;
    }

    dynamic value;
    if (T == String) {
      value = await _backend.getString(key);
    } else if (T == int) {
      value = await _backend.getInt(key);
    } else if (T == double) {
      value = await _backend.getDouble(key);
    } else if (T == bool) {
      value = await _backend.getBool(key);
    } else if (T == List<String>) {
      value = await _backend.getStringList(key);
    } else {
      value = await _backend.getJson(key);
    }

    value ??= _defaultValues[key];
    _cache[key] = value;

    return value as T?;
  }

  /// Set a value by key with optional debouncing.
  ///
  /// The value is immediately stored in the cache and the change is
  /// scheduled for persistence. If debouncing is enabled for this key,
  /// multiple rapid changes will be batched together.
  ///
  /// @param key the storage key
  /// @param value the value to store
  /// @param debounce optional debounce duration for this operation
  Future<void> setValue<T>(
      String key,
      T value, {
        Duration? debounce,
      }) async {
    _ensureInitialized();

    final oldValue = _cache[key];
    if (oldValue == value) {
      return;
    }

    _cache[key] = value;
    notifyListeners();
    _notifyKeyListeners(key, value);

    if (debounce != null) {
      _debounceTimers[key]?.cancel();
      _debounceTimers[key] = Timer(debounce, () {
        _markDirty(key);
        _debounceTimers.remove(key);
      });
    } else {
      _markDirty(key);
    }
  }

  /// Remove a value by key.
  ///
  /// This removes the value from both the cache and persistent storage.
  /// The default value will be returned on subsequent reads.
  ///
  /// @param key the storage key
  /// @returns true if a value was removed
  Future<bool> removeValue(String key) async {
    _ensureInitialized();

    final hadValue = _cache.containsKey(key);
    _cache.remove(key);
    _dirtyKeys.remove(key);

    final removed = await _backend.remove(key);

    if (hadValue) {
      notifyListeners();
      _notifyKeyListeners(key, _defaultValues[key]);
    }

    return removed;
  }

  /// Get a stream of value changes for a specific key.
  ///
  /// This stream will emit the current value immediately, then emit
  /// new values whenever the key is updated. Useful for reactive
  /// programming patterns.
  ///
  /// @param key the storage key to monitor
  /// @returns a stream of value changes
  Stream<T?> getValueStream<T>(String key) {
    _ensureInitialized();

    if (!_controllers.containsKey(key)) {
      _controllers[key] = StreamController<dynamic>.broadcast();
    }

    final controller = _controllers[key]!;

    getValue<T>(key).then((value) {
      if (!controller.isClosed) {
        controller.add(value);
      }
    });

    return controller.stream.cast<T?>();
  }

  /// Hydrate multiple keys from persistent storage.
  ///
  /// This method efficiently loads multiple values from storage in batch,
  /// updating the cache and notifying listeners of changes. Useful for
  /// initializing widget state from persisted values.
  ///
  /// @param keys the storage keys to hydrate
  /// @returns a map of key-value pairs that were successfully loaded
  Future<Map<String, dynamic>> hydrateKeys(List<String> keys) async {
    _ensureInitialized();

    final results = <String, dynamic>{};

    for (final key in keys) {
      try {
        final value = await getValue(key);
        if (value != null) {
          results[key] = value;
        }
      } catch (e) {
        debugPrint('Failed to hydrate key $key: $e');
      }
    }

    return results;
  }

  /// Force immediate persistence of all dirty values.
  ///
  /// This method bypasses the normal batch timer and immediately
  /// persists all pending changes. Useful before app shutdown
  /// or critical state transitions.
  Future<void> flush() async {
    await _flushPendingChanges();
  }

  /// Clear all cached and persisted state.
  ///
  /// This operation permanently removes all stored data.
  /// Use with extreme caution.
  Future<void> clearAll() async {
    _ensureInitialized();

    _cache.clear();
    _dirtyKeys.clear();
    _defaultValues.clear();

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    await _backend.clear();
    notifyListeners();

    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.add(null);
      }
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const PersistenceException(
        operation: 'operation',
        message: 'State manager not initialized. Call initialize() first.',
      );
    }
  }

  void _markDirty(String key) {
    _dirtyKeys.add(key);
  }

  void _startBatchTimer() {
    _batchTimer = Timer.periodic(_batchPersistInterval, (_) {
      _flushPendingChanges();
    });
  }

  Future<void> _flushPendingChanges() async {
    if (_dirtyKeys.isEmpty) {
      return;
    }

    final keysToFlush = Set<String>.from(_dirtyKeys);
    _dirtyKeys.clear();

    final futures = keysToFlush.map((key) async {
      try {
        final value = _cache[key];
        if (value == null) {
          await _backend.remove(key);
          return;
        }

        if (value is String) {
          await _backend.setString(key, value);
        } else if (value is int) {
          await _backend.setInt(key, value);
        } else if (value is double) {
          await _backend.setDouble(key, value);
        } else if (value is bool) {
          await _backend.setBool(key, value);
        } else if (value is List<String>) {
          await _backend.setStringList(key, value);
        } else {
          await _backend.setJson(key, value);
        }
      } catch (e) {
        debugPrint('Failed to persist key $key: $e');
        _markDirty(key);
      }
    });

    await Future.wait(futures);
  }

  void _notifyKeyListeners(String key, dynamic value) {
    final controller = _controllers[key];
    if (controller != null && !controller.isClosed) {
      controller.add(value);
    }
  }
}