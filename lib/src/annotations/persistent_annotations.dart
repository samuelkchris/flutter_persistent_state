/// Annotation that marks a class as having persistent state fields.
///
/// This annotation should be applied to StatefulWidget classes that contain
/// fields marked with @PersistentField. It triggers code generation to create
/// the necessary persistence and hydration logic.
///
/// Example:
/// ```dart
/// @PersistentState()
/// class MyWidget extends StatefulWidget {
///   @PersistentField(key: 'user_name')
///   final String userName;
///
///   const MyWidget({Key? key, required this.userName}) : super(key: key);
/// }
/// ```
class PersistentState {
  /// Optional backend type to use for persistence.
  /// Defaults to SharedPreferences backend if not specified.
  final Type? backend;

  /// Optional namespace for grouping related persistent fields.
  /// Useful for avoiding key collisions between different components.
  final String? namespace;

  /// Whether to automatically initialize persistence on widget creation.
  /// Defaults to true.
  final bool autoInitialize;

  const PersistentState({
    this.backend,
    this.namespace,
    this.autoInitialize = true,
  });
}

/// Annotation that marks a specific field as persistent.
///
/// Fields marked with this annotation will be automatically persisted
/// to the configured backend and hydrated when the widget is created.
/// The field type must be serializable by the chosen backend.
///
/// Supported types include: String, int, double, bool, List\<String>,
/// List\<int>, List\<double>, Map\<String, dynamic>, and custom objects
/// that implement proper serialization.
class PersistentField {
  /// Unique key for storing this field in the persistence backend.
  /// If not provided, the field name will be used as the key.
  final String? key;

  /// Default value to use if no persisted value exists.
  /// Must match the field type.
  final dynamic defaultValue;

  /// Custom serializer function name for complex types.
  /// The function should convert the object to a JSON-serializable format.
  final String? serializer;

  /// Custom deserializer function name for complex types.
  /// The function should reconstruct the object from the serialized format.
  final String? deserializer;

  /// Whether this field should be encrypted when persisted.
  /// Requires an encryption backend to be configured.
  final bool encrypted;

  /// Whether changes to this field should be debounced before persisting.
  /// Useful for frequently changing values like text input.
  final Duration? debounce;

  /// Optional validation function name to validate values before persistence.
  /// Function should return true if valid, false otherwise.
  final String? validator;

  const PersistentField({
    this.key,
    this.defaultValue,
    this.serializer,
    this.deserializer,
    this.encrypted = false,
    this.debounce,
    this.validator,
  });
}

/// Annotation for marking methods that should be called after persistence operations.
///
/// Methods marked with this annotation will be automatically called after
/// successful persistence operations. Useful for triggering side effects
/// or additional business logic.
class OnPersisted {
  /// Whether to call this method only for specific field keys.
  /// If null, the method will be called for any persistence operation.
  final List<String>? forKeys;

  const OnPersisted({this.forKeys});
}

/// Annotation for marking methods that should be called after hydration operations.
///
/// Methods marked with this annotation will be automatically called after
/// successful hydration from the persistence backend. Useful for initializing
/// derived state or triggering business logic based on restored values.
class OnHydrated {
  /// Whether to call this method only for specific field keys.
  /// If null, the method will be called after any hydration operation.
  final List<String>? forKeys;

  const OnHydrated({this.forKeys});
}

