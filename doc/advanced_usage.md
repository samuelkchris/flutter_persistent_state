# Advanced Usage Guide

This guide covers advanced features and patterns for Flutter Persistent State, including custom backends, encryption, performance optimization, and complex state management scenarios.

## 🏗️ **Custom Backends**

### Creating a Custom Backend

Implement the `PersistenceBackend` interface to create your own storage solution:

```dart
import 'package:flutter_persistent_state/flutter_persistent_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBackend implements PersistenceBackend {
  final FirebaseFirestore _firestore;
  final String _userId;
  bool _isInitialized = false;

  FirestoreBackend({
    required String userId,
    FirebaseFirestore? firestore,
  })  : _userId = userId,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    // Ensure Firebase is initialized
    _isInitialized = true;
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
  }

  @override
  Future<void> setString(String key, String value) async {
    await _firestore
        .collection('user_data')
        .doc(_userId)
        .collection('preferences')
        .doc(key)
        .set({'value': value, 'type': 'string'});
  }

  @override
  Future<String?> getString(String key) async {
    final doc = await _firestore
        .collection('user_data')
        .doc(_userId)
        .collection('preferences')
        .doc(key)
        .get();
    
    if (!doc.exists) return null;
    
    final data = doc.data();
    return data?['type'] == 'string' ? data?['value'] : null;
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _firestore
        .collection('user_data')
        .doc(_userId)
        .collection('preferences')
        .doc(key)
        .set({'value': value, 'type': 'int'});
  }

  @override
  Future<int?> getInt(String key) async {
    final doc = await _firestore
        .collection('user_data')
        .doc(_userId)
        .collection('preferences')
        .doc(key)
        .get();
    
    if (!doc.exists) return null;
    
    final data = doc.data();
    return data?['type'] == 'int' ? data?['value'] : null;
  }

  // ... implement other required methods

  @override
  Future<bool> remove(String key) async {
    try {
      await _firestore
          .collection('user_data')
          .doc(_userId)
          .collection('preferences')
          .doc(key)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clear() async {
    final batch = _firestore.batch();
    final docs = await _firestore
        .collection('user_data')
        .doc(_userId)
        .collection('preferences')
        .get();
    
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}
```

### Using Custom Backends

```dart
class CloudSyncedWidget extends StatefulWidget {
  @override
  State<CloudSyncedWidget> createState() => _CloudSyncedWidgetState();
}

class _CloudSyncedWidgetState extends State<CloudSyncedWidget>
    with PersistentStateMixin<CloudSyncedWidget> {

  // Use a custom state manager with Firestore backend
  @override
  PersistentStateManager get stateManager => 
      PersistentStateManager.getNamedInstance(
        'firestore',
        backend: FirestoreBackend(userId: 'current_user_id'),
      );

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'syncedData': persistentField('user_synced_data', defaultValue: {}),
    'lastSyncTime': persistentField('last_sync', defaultValue: 0),
  };

  // Your data is now synced to the cloud! 🚀
}
```

## 🔒 **Encryption and Security**

### Encrypted Storage Backend

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptedBackend implements PersistenceBackend {
  final PersistenceBackend _baseBackend;
  final Encrypter _encrypter;
  final IV _iv;

  EncryptedBackend({
    required PersistenceBackend baseBackend,
    required String encryptionKey,
  })  : _baseBackend = baseBackend,
        _encrypter = Encrypter(AES(Key.fromBase64(encryptionKey))),
        _iv = IV.fromSecureRandom(16);

  @override
  bool get isInitialized => _baseBackend.isInitialized;

  @override
  Future<void> initialize() => _baseBackend.initialize();

  @override
  Future<void> close() => _baseBackend.close();

  String _encrypt(String data) {
    final encrypted = _encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }

  String _decrypt(String encryptedData) {
    final encrypted = Encrypted.fromBase64(encryptedData);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  @override
  Future<void> setString(String key, String value) async {
    final encryptedValue = _encrypt(value);
    await _baseBackend.setString(key, encryptedValue);
  }

  @override
  Future<String?> getString(String key) async {
    final encryptedValue = await _baseBackend.getString(key);
    if (encryptedValue == null) return null;
    
    try {
      return _decrypt(encryptedValue);
    } catch (e) {
      // Handle decryption failure gracefully
      return null;
    }
  }

  // ... implement other methods with encryption
}
```

### Secure Sensitive Data

```dart
class SecureUserData extends StatefulWidget {
  @override
  State<SecureUserData> createState() => _SecureUserDataState();
}

class _SecureUserDataState extends State<SecureUserData>
    with PersistentStateMixin<SecureUserData> {

  @override
  PersistentStateManager get stateManager => 
      PersistentStateManager.getNamedInstance(
        'secure',
        backend: EncryptedBackend(
          baseBackend: SharedPreferencesBackend(),
          encryptionKey: 'your-256-bit-base64-key',
        ),
      );

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'sensitiveToken': persistentField('auth_token', defaultValue: ''),
    'userCredentials': persistentField('credentials', defaultValue: {}),
    'privateSettings': persistentField('private_prefs', defaultValue: {}),
  };

  // All data is now encrypted at rest! 🔐
}
```

## 🚀 **Performance Optimization**

### Batch Operations

```dart
class PerformantWidget extends StatefulWidget {
  @override
  State<PerformantWidget> createState() => _PerformantWidgetState();
}

class _PerformantWidgetState extends State<PerformantWidget>
    with PersistentStateMixin<PerformantWidget> {

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    // Use longer debounce for frequently changing values
    'searchQuery': persistentField('search', defaultValue: '')
      .withDebounce(const Duration(seconds: 1)),
    
    // Batch rapid changes
    'scrollPosition': persistentField('scroll_pos', defaultValue: 0.0)
      .withDebounce(const Duration(milliseconds: 200)),
    
    // No debounce for critical data
    'importantState': persistentField('critical', defaultValue: ''),
  };

  // Batch multiple updates together
  Future<void> updateMultipleValues() async {
    // These will be batched together automatically
    await setPersistentValue('field1', 'value1');
    await setPersistentValue('field2', 'value2');
    await setPersistentValue('field3', 'value3');
    
    // Force immediate flush if needed
    await stateManager.flush();
  }
}
```

### Custom Batch Intervals

```dart
// Create a manager with custom batching
final fastManager = PersistentStateManager.getNamedInstance(
  'fast',
  backend: SharedPreferencesBackend(),
  batchPersistInterval: const Duration(milliseconds: 100), // Very fast
);

final slowManager = PersistentStateManager.getNamedInstance(
  'slow',
  backend: SharedPreferencesBackend(),
  batchPersistInterval: const Duration(seconds: 5), // Battery-friendly
);
```

### Memory Management

```dart
class LargeDataWidget extends StatefulWidget {
  @override
  State<LargeDataWidget> createState() => _LargeDataWidgetState();
}

class _LargeDataWidgetState extends State<LargeDataWidget>
    with PersistentStateMixin<LargeDataWidget> {

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    // For large datasets, consider compression
    'largeDataset': persistentField('big_data', defaultValue: <String, dynamic>{})
      .withOnChanged(_handleLargeDataChange),
  };

  void _handleLargeDataChange(Map<String, dynamic> data) {
    // Implement custom compression/decompression if needed
    if (data.length > 1000) {
      print('Warning: Large dataset detected (${data.length} items)');
    }
  }

  @override
  void dispose() {
    // Always clean up resources
    disposePersistence();
    super.dispose();
  }
}
```

## 🧭 **Navigation Integration**

### Complete Navigation Setup

```dart
// main.dart
import 'package:flutter_persistent_state/flutter_persistent_state.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final navigationObserver = PersistentNavigationObserver(
      // Exclude certain routes from persistence
      excludedRoutes: {'/login', '/splash'},
      
      // Save route arguments
      saveArguments: true,
      
      // Enable deep links
      enableDeepLinks: true,
      
      // Custom should restore logic
      shouldRestore: (routeData) {
        final timestamp = routeData['timestamp'] as int?;
        if (timestamp != null) {
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          return age < Duration(days: 7).inMilliseconds; // Only restore recent routes
        }
        return true;
      },
    );

    return PersistentNavigationWrapper(
      observer: navigationObserver,
      restoreOnStart: true,
      maxRouteAge: const Duration(days: 7),
      onRestorationComplete: (restored, routeName) {
        print('Navigation restoration: $restored to $routeName');
      },
      child: MaterialApp(
        navigatorObservers: [navigationObserver],
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/profile': (context) => ProfileScreen(),
          '/settings': (context) => SettingsScreen(),
        },
      ),
    );
  }
}
```

### Route-Specific Persistence

```dart
class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  
  const ProductDetailsScreen({required this.productId});
  
  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with PersistentStateMixin<ProductDetailsScreen> {

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    // Use product ID in storage key for per-product persistence
    'viewHistory_${widget.productId}': persistentField(
      'product_view_${widget.productId}', 
      defaultValue: <String, dynamic>{},
    ),
    'scrollPosition_${widget.productId}': persistentField(
      'scroll_${widget.productId}', 
      defaultValue: 0.0,
    ),
  };

  @override
  void initState() {
    super.initState();
    initializePersistence();
    
    // Track view
    final history = getPersistentValue<Map<String, dynamic>>('viewHistory_${widget.productId}');
    history['lastViewed'] = DateTime.now().millisecondsSinceEpoch;
    history['viewCount'] = (history['viewCount'] ?? 0) + 1;
    setPersistentValue('viewHistory_${widget.productId}', history);
  }
}
```

## 📝 **Smart Text Field Integration**

### Advanced Text Field Features

```dart
class SmartFormPage extends StatefulWidget {
  @override
  State<SmartFormPage> createState() => _SmartFormPageState();
}

class _SmartFormPageState extends State<SmartFormPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        child: Column(
          children: [
            // Email field with validation and auto-save
            PersistentTextFormField(
              storageKey: 'user_email',
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              persistentValidator: (value) => value.contains('@') && value.contains('.'),
              debounce: const Duration(seconds: 1),
              showSaveIndicator: true,
              onSaved: () => print('Email saved!'),
              onError: (error) => print('Email save error: $error'),
            ),

            // Password field with custom persistence
            PersistentTextField(
              storageKey: 'draft_password',
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
              ),
              obscureText: true,
              validator: (value) => value.length >= 8 ? null : 'Too short',
              debounce: const Duration(milliseconds: 500),
              showSaveIndicator: false, // Don't show indicator for passwords
            ),

            // Auto-completing search field
            PersistentTextField(
              storageKey: 'search_query',
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) async {
                // Add to search history
                await PersistentTextUtils.addToSearchHistory(value);
              },
              onTap: () => _showSearchHistory(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchHistory() async {
    final history = await PersistentTextUtils.getSearchHistory();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final query = history[index];
          return ListTile(
            title: Text(query),
            leading: const Icon(Icons.history),
            onTap: () {
              // Use historical search
              Navigator.pop(context);
              _performSearch(query);
            },
          );
        },
      ),
    );
  }
}
```

### Bulk Text Operations

```dart
class BulkTextOperations {
  static Future<void> saveAllDrafts(
    Map<String, TextEditingController> controllers,
  ) async {
    final controllerMap = controllers.map(
      (key, controller) => MapEntry(
        key,
        PersistentTextController(storageKey: key, defaultValue: controller.text),
      ),
    );
    
    await PersistentTextUtils.saveAll(controllerMap);
    print('All drafts saved!');
  }

  static Future<void> clearAllDrafts(List<String> draftKeys) async {
    await PersistentTextUtils.clearAll(draftKeys);
    print('All drafts cleared!');
  }
}
```

## 🔄 **Data Migration**

### Version-Based Migration

```dart
class MigrationManager {
  static const String versionKey = 'app_data_version';
  static const int currentVersion = 3;

  static Future<void> performMigrations(PersistentStateManager manager) async {
    await manager.initialize();
    
    final currentDataVersion = await manager.getValue<int>(versionKey) ?? 1;
    
    if (currentDataVersion < currentVersion) {
      await _runMigrations(manager, currentDataVersion, currentVersion);
      await manager.setValue(versionKey, currentVersion);
    }
  }

  static Future<void> _runMigrations(
    PersistentStateManager manager,
    int fromVersion,
    int toVersion,
  ) async {
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      switch (version) {
        case 2:
          await _migrateToV2(manager);
          break;
        case 3:
          await _migrateToV3(manager);
          break;
      }
    }
  }

  static Future<void> _migrateToV2(PersistentStateManager manager) async {
    // Example: Rename old keys
    final oldValue = await manager.getValue<String>('old_user_name');
    if (oldValue != null) {
      await manager.setValue('user_name', oldValue);
      await manager.removeValue('old_user_name');
    }
  }

  static Future<void> _migrateToV3(PersistentStateManager manager) async {
    // Example: Convert data format
    final oldSettings = await manager.getValue<List<String>>('old_settings');
    if (oldSettings != null) {
      final newSettings = <String, bool>{};
      for (final setting in oldSettings) {
        newSettings[setting] = true;
      }
      await manager.setValue('settings_map', newSettings);
      await manager.removeValue('old_settings');
    }
  }
}

// Use in your app initialization
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: MigrationManager.performMigrations(
        PersistentStateManager.instance,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        
        return MaterialApp(/* your app */);
      },
    );
  }
}
```

## 🔍 **Debugging and Monitoring**

### Debug Logging

```dart
class DebugPersistentStateManager extends PersistentStateManager {
  @override
  Future<void> setValue<T>(String key, T value, {Duration? debounce}) async {
    print('🔄 Setting $key = $value');
    await super.setValue(key, value, debounce: debounce);
    print('✅ Set $key successfully');
  }

  @override
  Future<T?> getValue<T>(String key) async {
    final value = await super.getValue<T>(key);
    print('📖 Got $key = $value');
    return value;
  }
}

// Use in development
final debugManager = DebugPersistentStateManager.getNamedInstance(
  'debug',
  backend: SharedPreferencesBackend(),
);
```

### Performance Monitoring

```dart
class PerformanceMonitor {
  static final Map<String, List<int>> _operationTimes = {};

  static Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _operationTimes.putIfAbsent(operationName, () => []);
      _operationTimes[operationName]!.add(stopwatch.elapsedMilliseconds);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ Operation $operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  static void printStats() {
    print('\n📊 Performance Stats:');
    for (final entry in _operationTimes.entries) {
      final times = entry.value;
      final avg = times.reduce((a, b) => a + b) / times.length;
      print('${entry.key}: ${times.length} ops, avg ${avg.toStringAsFixed(1)}ms');
    }
  }
}

// Usage
await PerformanceMonitor.measureOperation('hydration', () async {
  await initializePersistence();
});
```

## 🧪 **Advanced Testing Patterns**

### Custom Test Backend

```dart
class ControllableBackend implements PersistenceBackend {
  final Map<String, dynamic> _data = {};
  bool _shouldFail = false;
  Duration _delay = Duration.zero;
  
  void simulateFailure(bool shouldFail) => _shouldFail = shouldFail;
  void simulateDelay(Duration delay) => _delay = delay;
  
  @override
  Future<void> setString(String key, String value) async {
    if (_delay > Duration.zero) await Future.delayed(_delay);
    if (_shouldFail) throw Exception('Simulated failure');
    _data[key] = value;
  }
  
  @override
  Future<String?> getString(String key) async {
    if (_delay > Duration.zero) await Future.delayed(_delay);
    if (_shouldFail) throw Exception('Simulated failure');
    return _data[key];
  }
  
  // ... implement other methods
}

// Test with simulated conditions
testWidgets('should handle storage failures gracefully', (tester) async {
  final backend = ControllableBackend();
  final manager = PersistentStateManager.getNamedInstance('test', backend: backend);
  
  // Test normal operation
  await manager.setValue('test', 'value');
  expect(await manager.getValue<String>('test'), 'value');
  
  // Test failure handling
  backend.simulateFailure(true);
  expect(() => manager.setValue('test', 'new'), throwsException);
  
  // Test slow operations
  backend.simulateFailure(false);
  backend.simulateDelay(const Duration(seconds: 2));
  
  final future = manager.getValue<String>('test');
  // Verify it doesn't complete immediately
  await tester.pump(const Duration(seconds: 1));
  expect(future, isA<Future>());
});
```

## 🎯 **Best Practices Summary**

### Do's ✅

- **Use descriptive storage keys** that won't conflict
- **Set appropriate default values** for all fields
- **Implement validation** for critical data
- **Use debouncing** for frequently changing values
- **Clean up resources** in dispose methods
- **Test with different backends** and failure scenarios
- **Use namespaced managers** for different app sections
- **Implement data migration** for app updates

### Don'ts ❌

- **Don't store sensitive data** without encryption
- **Don't use very short debounce times** (causes battery drain)
- **Don't forget error handling** for persistence operations
- **Don't store very large objects** without considering performance
- **Don't use persistence** for temporary UI state
- **Don't ignore validation errors**
- **Don't mix different data formats** in the same field

### Performance Tips 🚀

1. **Batch related updates** together
2. **Use appropriate debounce timings** (500ms-2s for most cases)
3. **Prefer primitive types** over complex objects when possible
4. **Clean up unused data** periodically
5. **Monitor storage usage** in large apps
6. **Use lazy loading** for large datasets
7. **Consider compression** for very large objects

## 🎉 **Conclusion**

You now have the knowledge to implement advanced persistent state patterns in your Flutter apps. Remember to:

- Start simple and add complexity as needed
- Test thoroughly with different scenarios
- Monitor performance in production
- Keep security in mind for sensitive data

For more specific guidance, check out:
- [API Reference](api_reference.md) - Complete method documentation
- [Testing Guide](testing.md) - Comprehensive testing strategies
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

Happy coding! 🚀