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

    return _persistentValues[fieldName] ?? config.defaultValue;
  }

  /// Set the value of a persistent field.
  ///
  /// This method updates the local cache, persists the value, and triggers
  /// a rebuild if the value has changed. If validation is configured for
  /// the field, it will be executed before setting the value.
  ///
  /// @param fieldName the name of the persistent field
  /// @param value the new value to set
  /// @throws ArgumentError if the field is unknown or validation fails
  Future<void> setPersistentValue<T>(String fieldName, T value) async {
    final config = persistentFields[fieldName];
    if (config == null) {
      throw ArgumentError('Unknown persistent field: $fieldName');
    }

    if (config.validator != null && !config.validator!(value)) {
      throw ArgumentError('Validation failed for field: $fieldName');
    }

    final oldValue = _persistentValues[fieldName];
    if (oldValue == value) {
      return;
    }

    _persistentValues[fieldName] = value;

    await stateManager.setValue(
      config.storageKey,
      value,
      debounce: config.debounce,
    );

    if (mounted) {
      setState(() {});
    }

    if (config.onChanged != null) {
      config.onChanged!(value);
    }
  }

  /// Initialize the persistence mixin and hydrate values from storage.
  ///
  /// This method should be called from the widget's initState method.
  /// It sets up listeners for reactive updates and loads persisted values.
  @protected
  Future<void> initializePersistence() async {
    if (!stateManager.isInitialized) {
      await stateManager.initialize();
    }

    await _hydrateValues();
    _setupListeners();
    _isHydrated = true;

    if (mounted) {
      setState(() {});
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
        .getValueStream<T>(config.storageKey)
        .map((value) => value ?? config.defaultValue as T);
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

    await stateManager.removeValue(config.storageKey);
    _persistentValues[fieldName] = config.defaultValue;

    if (mounted) {
      setState(() {});
    }

    if (config.onChanged != null) {
      config.onChanged!(config.defaultValue);
    }
  }

  /// Reset all persistent fields to their default values.
  ///
  /// This method removes all persisted values for this widget
  /// and resets all fields to their configured defaults.
  Future<void> resetAllPersistentFields() async {
    final futures = persistentFields.keys.map(resetPersistentField);
    await Future.wait(futures);
  }

  Future<void> _hydrateValues() async {
    final configs = persistentFields;
    final storageKeys = configs.values.map((c) => c.storageKey).toList();

    for (final config in configs.values) {
      stateManager.registerDefault(config.storageKey, config.defaultValue);
    }

    final hydratedValues = await stateManager.hydrateKeys(storageKeys);

    for (final entry in configs.entries) {
      final fieldName = entry.key;
      final config = entry.value;
      final value = hydratedValues[config.storageKey] ?? config.defaultValue;
      _persistentValues[fieldName] = value;
    }
  }

  void _setupListeners() {
    for (final entry in persistentFields.entries) {
      final fieldName = entry.key;
      final config = entry.value;

      final subscription =
          stateManager.getValueStream(config.storageKey).listen((value) {
        if (value != _persistentValues[fieldName]) {
          _persistentValues[fieldName] = value ?? config.defaultValue;

          if (mounted) {
            setState(() {});
          }

          if (config.onChanged != null) {
            config.onChanged!(value ?? config.defaultValue);
          }
        }
      });

      _subscriptions[fieldName] = subscription;
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
