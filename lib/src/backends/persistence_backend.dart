import 'dart:async';

/// Abstract interface for persistence backends.
///
/// This interface defines the contract that all persistence backends must
/// implement. It provides type-safe methods for storing and retrieving
/// different data types, along with lifecycle management and error handling.
///
/// Implementations should handle serialization/deserialization internally
/// and provide appropriate error handling for storage failures.
abstract class PersistenceBackend {
  /// Initialize the backend and prepare it for use.
  /// 
  /// This method should be called before any other operations.
  /// It should handle any necessary setup, such as opening database
  /// connections or initializing storage systems.
  ///
  /// @throws PersistenceException if initialization fails
  Future<void> initialize();

  /// Close the backend and release any resources.
  ///
  /// This method should be called when the backend is no longer needed.
  /// It should properly clean up resources and close any open connections.
  Future<void> close();

  /// Check if the backend is currently initialized and ready for use.
  ///
  /// @returns true if the backend is ready, false otherwise
  bool get isInitialized;

  /// Store a string value with the specified key.
  ///
  /// @param key the unique identifier for the value
  /// @param value the string value to store
  /// @throws PersistenceException if the operation fails
  Future<void> setString(String key, String value);

  /// Retrieve a string value by key.
  ///
  /// @param key the unique identifier for the value
  /// @returns the stored string value, or null if not found
  /// @throws PersistenceException if the operation fails
  Future<String?> getString(String key);

  /// Store an integer value with the specified key.
  ///
  /// @param key the unique identifier for the value
  /// @param value the integer value to store
  /// @throws PersistenceException if the operation fails
  Future<void> setInt(String key, int value);

  /// Retrieve an integer value by key.
  ///
  /// @param key the unique identifier for the value
  /// @returns the stored integer value, or null if not found
  /// @throws PersistenceException if the operation fails
  Future<int?> getInt(String key);

  /// Store a double value with the specified key.
  ///
  /// @param key the unique identifier for the value
  /// @param value the double value to store
  /// @throws PersistenceException if the operation fails
  Future<void> setDouble(String key, double value);

  /// Retrieve a double value by key.
  ///
  /// @param key the unique identifier for the value
  /// @returns the stored double value, or null if not found
  /// @throws PersistenceException if the operation fails
  Future<double?> getDouble(String key);

  /// Store a boolean value with the specified key.
  ///
  /// @param key the unique identifier for the value
  /// @param value the boolean value to store
  /// @throws PersistenceException if the operation fails
  Future<void> setBool(String key, bool value);

  /// Retrieve a boolean value by key.
  ///
  /// @param key the unique identifier for the value
  /// @returns the stored boolean value, or null if not found
  /// @throws PersistenceException if the operation fails
  Future<bool?> getBool(String key);

  /// Store a list of strings with the specified key.
  ///
  /// @param key the unique identifier for the value
  /// @param value the list of strings to store
  /// @throws PersistenceException if the operation fails
  Future<void> setStringList(String key, List<String> value);

  /// Retrieve a list of strings by key.
  ///
  /// @param key the unique identifier for the value
  /// @returns the stored list of strings, or null if not found
  /// @throws PersistenceException if the operation fails
  Future<List<String>?> getStringList(String key);

  /// Store arbitrary JSON-serializable data with the specified key.
  ///
  /// The data will be serialized to JSON before storage. The value
  /// must be JSON-serializable (primitives, Map, List, or objects
  /// with proper toJson methods).
  ///
  /// @param key the unique identifier for the value
  /// @param value the JSON-serializable value to store
  /// @throws PersistenceException if the operation fails
  Future<void> setJson(String key, dynamic value);

  /// Retrieve and deserialize JSON data by key.
  ///
  /// @param key the unique identifier for the value
  /// @returns the deserialized value, or null if not found
  /// @throws PersistenceException if the operation fails
  Future<dynamic> getJson(String key);

  /// Remove a value by key.
  ///
  /// @param key the unique identifier for the value to remove
  /// @returns true if a value was removed, false if the key didn't exist
  /// @throws PersistenceException if the operation fails
  Future<bool> remove(String key);

  /// Remove all stored values.
  ///
  /// This operation will permanently delete all data managed by this backend.
  /// Use with caution.
  ///
  /// @throws PersistenceException if the operation fails
  Future<void> clear();

  /// Check if a key exists in the backend.
  ///
  /// @param key the unique identifier to check
  /// @returns true if the key exists, false otherwise
  /// @throws PersistenceException if the operation fails
  Future<bool> containsKey(String key);

  /// Get all keys currently stored in the backend.
  ///
  /// @returns a set of all stored keys
  /// @throws PersistenceException if the operation fails
  Future<Set<String>> getKeys();
}

/// Exception thrown by persistence backends when operations fail.
///
/// This exception provides detailed information about persistence failures,
/// including the operation that failed, the key involved, and the underlying
/// cause of the failure.
class PersistenceException implements Exception {
  /// The operation that failed (e.g., 'setString', 'initialize').
  final String operation;

  /// The key involved in the operation, if applicable.
  final String? key;

  /// A human-readable description of the error.
  final String message;

  /// The underlying exception that caused this failure, if any.
  final Object? cause;

  /// The stack trace from the underlying exception, if any.
  final StackTrace? stackTrace;

  const PersistenceException({
    required this.operation,
    this.key,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('PersistenceException: $operation failed');
    if (key != null) {
      buffer.write(' (key: $key)');
    }
    buffer.write(' - $message');
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Configuration options for persistence backends.
///
/// This class provides common configuration options that can be used
/// by different backend implementations. Specific backends may extend
/// this class to provide additional configuration options.
class BackendConfiguration {
  /// Optional namespace to prefix all keys with.
  /// Useful for avoiding key collisions in shared storage.
  final String? namespace;

  /// Whether to enable encryption for stored values.
  /// Requires the backend to support encryption.
  final bool enableEncryption;

  /// Optional encryption key for backends that support encryption.
  /// If not provided, a default key generation strategy will be used.
  final String? encryptionKey;

  /// Whether to compress stored values to reduce storage space.
  /// May impact performance for frequently accessed values.
  final bool enableCompression;

  /// Maximum number of retry attempts for failed operations.
  final int maxRetries;

  /// Delay between retry attempts for failed operations.
  final Duration retryDelay;

  const BackendConfiguration({
    this.namespace,
    this.enableEncryption = false,
    this.encryptionKey,
    this.enableCompression = false,
    this.maxRetries = 3,
    this.retryDelay = const Duration(milliseconds: 100),
  });

  /// Create a configuration with a namespace prefix.
  ///
  /// @param namespace the namespace to use for key prefixing
  /// @returns a new configuration with the specified namespace
  BackendConfiguration withNamespace(String namespace) {
    return BackendConfiguration(
      namespace: namespace,
      enableEncryption: enableEncryption,
      encryptionKey: encryptionKey,
      enableCompression: enableCompression,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
    );
  }

  /// Apply namespace prefixing to a key if configured.
  ///
  /// @param key the original key
  /// @returns the key with namespace prefix applied, or original key if no namespace
  String applyNamespace(String key) {
    return namespace != null ? '$namespace:$key' : key;
  }
}