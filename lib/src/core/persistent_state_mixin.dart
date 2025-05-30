import 'dart:async';

import 'package:flutter/widgets.dart';

import 'persistent_state_manager.dart';

/// Mixin that provides automatic persistence capabilities to StatefulWidgets.
///
/// This mixin integrates with the PersistentStateManager to provide seamless
/// state persistence and hydration. Widgets using this mixin can define
/// persistent fields using annotations, and the mixin handles all the
/// boilerplate for loading, saving, and reacting to changes.
///
/// Example usage:
/// ```dart
/// class MyWidgetState extends State<MyWidget> with PersistentStateMixin<MyWidget> {
///   late String userName;
///   late int userAge;
///
///   @override
///   Map<String, dynamic> get persistentFields => {
///     'userName': persistentField('user_name', defaultValue: 'Anonymous'),
///     'userAge': persistentField('user_age', defaultValue: 0),
///   };
/// }
/// ```
mixin PersistentStateMixin<T extends StatefulWidget> on State<T> {
  PersistentStateManager? _manager;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, dynamic> _persistentValues = {};
  bool _isHydrated = false;
  bool _isInitializing = false;

  /// Override this getter to define which fields should be persistent.
  ///
  /// Return a map where keys are field names and values are PersistentFieldConfig
  /// objects that define the storage key, default value, and other options.
  ///
  /// @returns map of field name to persistence configuration
  Map<String, PersistentFieldConfig> get persistentFields;

  /// Get the state manager instance to use for this widget.
  ///
  /// By default, this returns the default singleton instance. Override
  /// this method to use a custom or named instance.
  ///
  /// @returns the state manager instance to use
  PersistentStateManager get stateManager =>
      _manager ??= PersistentStateManager.instance;

  /// Get the current value of a persistent field.
  ///
  /// This method returns the cached value if available, or the default
  /// value if the field hasn't been hydrated yet.
  ///
  /// @param fieldName the name of the persistent field
  /// @returns the current value of the field
  T getPersistentValue<T>(String fieldName) {
    final config = persistentFields[fieldName];
    if (config == null) {
      throw ArgumentError('Unknown persistent field: $fieldName');
    }

    final value = _persistentValues[fieldName];

    try {
      // If value is null, return default value
      if (value == null) {
        return config.defaultValue as T;
      }

      // If value is already the correct type, return it
      if (value is T) {
        return value;
      }

      // Handle type conversions
      return _safeCastValue<T>(value, config.defaultValue);
    } catch (e) {
      debugPrint('Failed to cast value for field $fieldName: $e');
      return config.defaultValue as T;
    }
  }

  /// Safely cast a value to the target type with fallback to default.
  T _safeCastValue<T>(dynamic value, dynamic defaultValue) {
    try {
      // Handle Map type conversions
      if (T.toString().startsWith('Map<String,') && value is Map) {
        if (T.toString().contains('bool')) {
          return Map<String, bool>.from(value) as T;
        } else if (T.toString().contains('int')) {
          return Map<String, int>.from(value) as T;
        } else if (T.toString().contains('String')) {
          return Map<String, String>.from(value) as T;
        } else {
          return Map<String, dynamic>.from(value) as T;
        }
      }

      // Handle List type conversions
      if (T.toString().startsWith('List<') && value is List) {
        if (T.toString().contains('String')) {
          return List<String>.from(value.map((e) => e.toString())) as T;
        } else if (T.toString().contains('int')) {
          return List<int>.from(value.where((e) => e is num).map((e) => (e as num).toInt())) as T;
        } else {
          return List.from(value) as T;
        }
      }

      // Handle primitive type conversions
      if (T == String) {
        return value.toString() as T;
      } else if (T == int && value is num) {
        return value.toInt() as T;
      } else if (T == double && value is num) {
        return value.toDouble() as T;
      } else if (T == bool) {
        if (value is bool) return value as T;
        if (value is String) {
          return (value.toLowerCase() == 'true') as T;
        }
        return (value == 1) as T;
      }

      // Attempt direct cast
      return value as T;
    } catch (e) {
      debugPrint('Type conversion failed for value $value to type $T: $e');
      return defaultValue as T;
    }
  }

  /// Set the value of a persistent field with validation and error handling.
  Future<void> setPersistentValue<T>(String fieldName, T value) async {
    final config = persistentFields[fieldName];
    if (config == null) {
      throw ArgumentError('Unknown persistent field: $fieldName');
    }

    if (config.validator != null) {
      try {
        if (!config.validator!(value)) {
          throw ArgumentError('Validation failed for field: $fieldName');
        }
      } catch (e) {
        debugPrint('Validation error for field $fieldName: $e');
        throw ArgumentError('Validation failed for field: $fieldName');
      }
    }

    final oldValue = _persistentValues[fieldName];
    if (oldValue == value) {
      return;
    }

    _persistentValues[fieldName] = value;

    try {
      await stateManager.setValue(
        config.storageKey,
        value,
        debounce: config.debounce,
      );

      if (mounted) {
        setState(() {});
      }

      if (config.onChanged != null) {
        try {
          config.onChanged!(value);
        } catch (e) {
          debugPrint('OnChanged callback error for field $fieldName: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to persist field $fieldName: $e');
      _persistentValues[fieldName] = oldValue;
      rethrow;
    }
  }

  /// Initialize the persistence mixin and hydrate values from storage.
  ///
  /// This method should be called from the widget's initState method.
  /// It sets up listeners for reactive updates and loads persisted values.
  @protected
  Future<void> initializePersistence() async {
    if (_isInitializing || _isHydrated) {
      return;
    }

    _isInitializing = true;

    try {
      if (!stateManager.isInitialized) {
        await stateManager.initialize();
      }

      await _hydrateValues();
      _setupListeners();
      _isHydrated = true;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to initialize persistence: $e');
      _isHydrated = true;
      if (mounted) {
        setState(() {});
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Clean up persistence resources.
  ///
  /// This method should be called from the widget's dispose method.
  /// It cancels all subscriptions and cleans up resources.
  @protected
  void disposePersistence() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Check if all persistent fields have been hydrated from storage.
  ///
  /// @returns true if hydration is complete, false otherwise
  bool get isHydrated => _isHydrated;

  /// Get a stream of changes for a specific persistent field.
  ///
  /// This stream will emit the current value immediately, then emit
  /// new values whenever the field is updated from any source.
  ///
  /// @param fieldName the name of the persistent field
  /// @returns a stream of value changes
  Stream<T> getPersistentValueStream<T>(String fieldName) {
    final config = persistentFields[fieldName];
    if (config == null) {
      throw ArgumentError('Unknown persistent field: $fieldName');
    }

    return stateManager
        .getValueStream(config.storageKey)
        .map((value) {
          try {
            return _safeCastValue<T>(value, config.defaultValue);
          } catch (e) {
            debugPrint('Failed to cast value for field $fieldName: $e');
            return config.defaultValue as T;
          }
        })
        .distinct();
  }

  /// Reset a persistent field to its default value.
  ///
  /// This method removes the persisted value and resets the field
  /// to its configured default value.
  ///
  /// @param fieldName the name of the persistent field to reset
  Future<void> resetPersistentField(String fieldName) async {
    final config = persistentFields[fieldName];
    if (config == null) {
      throw ArgumentError('Unknown persistent field: $fieldName');
    }

    try {
      await stateManager.removeValue(config.storageKey);
      _persistentValues[fieldName] = config.defaultValue;

      if (mounted) {
        setState(() {});
      }

      if (config.onChanged != null) {
        try {
          config.onChanged!(config.defaultValue);
        } catch (e) {
          debugPrint('OnChanged callback error during reset for field $fieldName: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to reset field $fieldName: $e');
      rethrow;
    }
  }

  /// Reset all persistent fields to their default values.
  ///
  /// This method removes all persisted values for this widget
  /// and resets all fields to their configured defaults.
  Future<void> resetAllPersistentFields() async {
    final futures = persistentFields.keys.map((fieldName) async {
      try {
        await resetPersistentField(fieldName);
      } catch (e) {
        debugPrint('Failed to reset field $fieldName: $e');
      }
    });
    await Future.wait(futures);
  }

  Future<void> _hydrateValues() async {
    final configs = persistentFields;

    for (final entry in configs.entries) {
      final fieldName = entry.key;
      final config = entry.value;

      try {
        stateManager.registerDefault(config.storageKey, config.defaultValue);
      } catch (e) {
        debugPrint('Failed to register default for field $fieldName: $e');
      }
    }


    for (final entry in configs.entries) {
      final fieldName = entry.key;
      final config = entry.value;

      try {
        final value = await stateManager.getValue(config.storageKey);
        _persistentValues[fieldName] = value ?? config.defaultValue;
      } catch (e) {
        debugPrint('Failed to hydrate field $fieldName: $e');
        _persistentValues[fieldName] = config.defaultValue;
      }
    }
  }

  void _setupListeners() {
    for (final entry in persistentFields.entries) {
      final fieldName = entry.key;
      final config = entry.value;

      try {
        final subscription = stateManager
            .getValueStream(config.storageKey)
            .listen(
          (value) {
            try {
              final newValue = value ?? config.defaultValue;
              if (newValue != _persistentValues[fieldName]) {
                _persistentValues[fieldName] = newValue;

                if (mounted) {
                  setState(() {});
                }

                if (config.onChanged != null) {
                  try {
                    config.onChanged!(newValue);
                  } catch (e) {
                    debugPrint('OnChanged callback error for field $fieldName: $e');
                  }
                }
              }
            } catch (e) {
              debugPrint('Error processing value change for field $fieldName: $e');
            }
          },
          onError: (error) {
            debugPrint('Stream error for field $fieldName: $error');
          },
        );

        _subscriptions[fieldName] = subscription;
      } catch (e) {
        debugPrint('Failed to setup listener for field $fieldName: $e');
      }
    }
  }
}

/// Configuration for a persistent field.
///
/// This class defines how a field should be persisted, including its
/// storage key, default value, validation rules, and change callbacks.
/// It provides a fluent interface for configuring persistence behavior.
class PersistentFieldConfig<T> {
  /// The storage key to use for this field.
  final String storageKey;

  /// The default value to use when no persisted value exists.
  final T defaultValue;

  /// Optional validation function to validate values before persistence.
  final bool Function(T value)? validator;

  /// Optional callback to execute when the field value changes.
  final void Function(T value)? onChanged;

  /// Optional debounce duration for this field.
  final Duration? debounce;

  const PersistentFieldConfig({
    required this.storageKey,
    required this.defaultValue,
    this.validator,
    this.onChanged,
    this.debounce,
  });

  /// Create a persistent field configuration with a storage key and default value.
  ///
  /// @param storageKey the key to use for persistence
  /// @param defaultValue the default value when no persisted value exists
  /// @returns a new field configuration
  static PersistentFieldConfig<T> field<T>(
    String storageKey, {
    required T defaultValue,
  }) {
    return PersistentFieldConfig<T>(
      storageKey: storageKey,
      defaultValue: defaultValue,
    );
  }

  /// Add validation to this field configuration.
  ///
  /// @param validator function that returns true if the value is valid
  /// @returns a new configuration with validation added
  PersistentFieldConfig<T> withValidation(bool Function(T value) validator) {
    return PersistentFieldConfig<T>(
      storageKey: storageKey,
      defaultValue: defaultValue,
      validator: validator,
      onChanged: onChanged,
      debounce: debounce,
    );
  }

  /// Add a change callback to this field configuration.
  ///
  /// @param onChanged callback to execute when the value changes
  /// @returns a new configuration with the change callback added
  PersistentFieldConfig<T> withOnChanged(void Function(T value) onChanged) {
    return PersistentFieldConfig<T>(
      storageKey: storageKey,
      defaultValue: defaultValue,
      validator: validator,
      onChanged: onChanged,
      debounce: debounce,
    );
  }

  /// Add debouncing to this field configuration.
  ///
  /// @param debounce duration to debounce rapid changes
  /// @returns a new configuration with debouncing added
  PersistentFieldConfig<T> withDebounce(Duration debounce) {
    return PersistentFieldConfig<T>(
      storageKey: storageKey,
      defaultValue: defaultValue,
      validator: validator,
      onChanged: onChanged,
      debounce: debounce,
    );
  }
}

/// Convenience function to create a persistent field configuration.
///
/// This function provides a more concise way to create field configurations
/// in the persistentFields getter.
///
/// @param storageKey the key to use for persistence
/// @param defaultValue the default value when no persisted value exists
/// @returns a new field configuration
PersistentFieldConfig<T> persistentField<T>(
  String storageKey, {
  required T defaultValue,
}) {
  return PersistentFieldConfig.field<T>(
    storageKey,
    defaultValue: defaultValue,
  );
}
