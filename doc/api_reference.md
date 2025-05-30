# API Reference

Complete API documentation for Flutter Persistent State package.

## 📋 **Core Classes**

### PersistentStateMixin<T>

The main mixin that provides persistence capabilities to StatefulWidget classes.

#### Properties

```dart
bool get isHydrated
```
Returns `true` when all persistent fields have been loaded from storage.

```dart
PersistentStateManager get stateManager
```
The state manager instance used by this widget. Override to use a custom manager.

```dart
Map<String, PersistentFieldConfig> get persistentFields
```
**Abstract property** - Override to define your persistent fields.

#### Methods

##### initializePersistence()

```dart
Future<void> initializePersistence()
```

Initializes the persistence system and hydrates values from storage.

**Usage:**
```dart
@override
void initState() {
  super.initState();
  initializePersistence();
}
```

**Throws:**
- `PersistenceException` if initialization fails

##### disposePersistence()

```dart
void disposePersistence()
```

Cleans up persistence resources. Call from your widget's `dispose()` method.

**Usage:**
```dart
@override
void dispose() {
  disposePersistence();
  super.dispose();
}
```

##### getPersistentValue<T>()

```dart
T getPersistentValue<T>(String fieldName)
```

Gets the current value of a persistent field.

**Parameters:**
- `fieldName` - The name of the field as defined in `persistentFields`

**Returns:**
- The current value or default value if not yet hydrated

**Throws:**
- `ArgumentError` if field name is not found

**Example:**
```dart
final userName = getPersistentValue<String>('userName');
final count = getPersistentValue<int>('counter');
```

##### setPersistentValue<T>()

```dart
Future<void> setPersistentValue<T>(String fieldName, T value)
```

Sets the value of a persistent field.

**Parameters:**
- `fieldName` - The name of the field
- `value` - The new value to set

**Throws:**
- `ArgumentError` if field name is not found or validation fails

**Example:**
```dart
await setPersistentValue('userName', 'John Doe');
await setPersistentValue('counter', 42);
```

##### getPersistentValueStream<T>()

```dart
Stream<T> getPersistentValueStream<T>(String fieldName)
```

Gets a stream of value changes for a persistent field.

**Parameters:**
- `fieldName` - The name of the field

**Returns:**
- Stream that emits the current value and all future changes

**Example:**
```dart
StreamBuilder<String>(
  stream: getPersistentValueStream<String>('userName'),
  builder: (context, snapshot) {
    return Text(snapshot.data ?? 'Loading...');
  },
)
```

##### resetPersistentField()

```dart
Future<void> resetPersistentField(String fieldName)
```

Resets a field to its default value.

**Parameters:**
- `fieldName` - The name of the field to reset

##### resetAllPersistentFields()

```dart
Future<void> resetAllPersistentFields()
```

Resets all persistent fields to their default values.

---

### PersistentStateManager

Manages persistence operations and coordinates between widgets and storage backends.

#### Static Methods

##### instance

```dart
static PersistentStateManager get instance
```

Gets the default singleton instance using SharedPreferences backend.

##### getNamedInstance()

```dart
static PersistentStateManager getNamedInstance(
  String name, {
  PersistenceBackend? backend,
  Duration? batchPersistInterval,
})
```

Gets a named instance with custom configuration.

**Parameters:**
- `name` - Unique identifier for this instance
- `backend` - Custom backend (default: SharedPreferencesBackend)
- `batchPersistInterval` - How often to batch persist changes (default: 500ms)

**Example:**
```dart
final customManager = PersistentStateManager.getNamedInstance(
  'encrypted',
  backend: EncryptedBackend(key: 'secret'),
  batchPersistInterval: Duration(seconds: 1),
);
```

#### Instance Methods

##### initialize()

```dart
Future<void> initialize()
```

Initializes the state manager and its backend.

##### dispose()

```dart
Future<void> dispose()
```

Disposes the manager and cleans up resources.

##### registerDefault()

```dart
void registerDefault(String key, dynamic defaultValue)
```

Registers a default value for a storage key.

##### getValue<T>()

```dart
Future<T?> getValue<T>(String key)
```

Gets a value from storage with type casting.

##### setValue<T>()

```dart
Future<void> setValue<T>(String key, T value, {Duration? debounce})
```

Sets a value in storage with optional debouncing.

##### removeValue()

```dart
Future<bool> removeValue(String key)
```

Removes a value from storage.

##### getValueStream<T>()

```dart
Stream<T?> getValueStream<T>(String key)
```

Gets a stream of value changes for a key.

##### hydrateKeys()

```dart
Future<Map<String, dynamic>> hydrateKeys(List<String> keys)
```

Loads multiple keys from storage efficiently.

##### flush()

```dart
Future<void> flush()
```

Forces immediate persistence of all pending changes.

##### clearAll()

```dart
Future<void> clearAll()
```

Clears all stored data.

---

### PersistentFieldConfig<T>

Configuration for a persistent field.

#### Constructor

```dart
const PersistentFieldConfig({
  required String storageKey,
  required T defaultValue,
  bool Function(T value)? validator,
  void Function(T value)? onChanged,
  Duration? debounce,
})
```

#### Factory Methods

##### field()

```dart
static PersistentFieldConfig<T> field<T>(
  String storageKey, {
  required T defaultValue,
})
```

Creates a basic field configuration.

#### Fluent Configuration Methods

##### withValidation()

```dart
PersistentFieldConfig<T> withValidation(bool Function(T value) validator)
```

Adds validation to the field.

**Example:**
```dart
persistentField('email', defaultValue: '')
  .withValidation((value) => value.contains('@'))
```

##### withOnChanged()

```dart
PersistentFieldConfig<T> withOnChanged(void Function(T value) onChanged)
```

Adds a change callback.

**Example:**
```dart
persistentField('theme', defaultValue: 'light')
  .withOnChanged((theme) => updateAppTheme(theme))
```

##### withDebounce()

```dart
PersistentFieldConfig<T> withDebounce(Duration debounce)
```

Adds debouncing to prevent excessive saves.

**Example:**
```dart
persistentField('searchQuery', defaultValue: '')
  .withDebounce(Duration(milliseconds: 500))
```

---

## 🛠️ **Backend Classes**

### PersistenceBackend

Abstract interface for storage backends.

#### Abstract Methods

```dart
Future<void> initialize()
Future<void> close()
bool get isInitialized

Future<void> setString(String key, String value)
Future<String?> getString(String key)

Future<void> setInt(String key, int value)
Future<int?> getInt(String key)

Future<void> setDouble(String key, double value)
Future<double?> getDouble(String key)

Future<void> setBool(String key, bool value)
Future<bool?> getBool(String key)

Future<void> setStringList(String key, List<String> value)
Future<List<String>?> getStringList(String key)

Future<void> setJson(String key, dynamic value)
Future<dynamic> getJson(String key)

Future<bool> remove(String key)
Future<void> clear()
Future<bool> containsKey(String key)
Future<Set<String>> getKeys()
```

### SharedPreferencesBackend

Default backend using Flutter's SharedPreferences.

#### Constructor

```dart
SharedPreferencesBackend({BackendConfiguration? config})
```

**Example:**
```dart
final backend = SharedPreferencesBackend(
  config: BackendConfiguration(
    namespace: 'myapp',
    maxRetries: 5,
    retryDelay: Duration(milliseconds: 200),
  ),
);
```

### BackendConfiguration

Configuration options for backends.

#### Constructor

```dart
const BackendConfiguration({
  String? namespace,
  bool enableEncryption = false,
  String? encryptionKey,
  bool enableCompression = false,
  int maxRetries = 3,
  Duration retryDelay = const Duration(milliseconds: 100),
})
```

#### Methods

##### withNamespace()

```dart
BackendConfiguration withNamespace(String namespace)
```

Creates a configuration with namespace prefixing.

##### applyNamespace()

```dart
String applyNamespace(String key)
```

Applies namespace prefix to a key.

---

## 🧭 **Navigation Classes**

### PersistentNavigationObserver

Route observer that persists navigation state.

#### Constructor

```dart
PersistentNavigationObserver({
  PersistentStateManager? stateManager,
  String routeStackKey = 'navigation_route_stack',
  String currentRouteKey = 'navigation_current_route',
  bool saveArguments = true,
  bool enableDeepLinks = true,
  Set<String>? excludedRoutes,
})
```

#### Methods

##### getLastRoute()

```dart
Future<Map<String, dynamic>?> getLastRoute()
```

Gets the last saved route information.

##### getRouteHistory()

```dart
Future<List<Map<String, dynamic>>> getRouteHistory()
```

Gets the complete route history.

##### clearNavigationState()

```dart
Future<void> clearNavigationState()
```

Clears all saved navigation state.

### PersistentNavigationWrapper

Widget that automatically restores navigation state.

#### Constructor

```dart
const PersistentNavigationWrapper({
  Key? key,
  required Widget child,
  required PersistentNavigationObserver observer,
  bool restoreOnStart = true,
  Duration maxRouteAge = const Duration(days: 7),
  bool Function(Map<String, dynamic> routeData)? shouldRestore,
  void Function(bool restored, String? routeName)? onRestorationComplete,
})
```

---

## 📝 **Text Field Classes**

### PersistentTextField

A TextField that automatically persists its content.

#### Constructor

```dart
const PersistentTextField({
  Key? key,
  required String storageKey,
  PersistentStateManager? stateManager,
  String defaultValue = '',
  Duration debounce = const Duration(milliseconds: 500),
  String? Function(String)? validator,
  void Function(String)? onChanged,
  void Function()? onSaved,
  void Function(String?)? onError,
  bool showSaveIndicator = true,
  bool showErrors = true,
  bool autoSave = true,
  
  // All standard TextField properties...
  InputDecoration? decoration,
  TextInputType? keyboardType,
  // ... etc
})
```

### PersistentTextFormField

FormField wrapper for PersistentTextField.

#### Constructor

```dart
PersistentTextFormField({
  Key? key,
  required String storageKey,
  // ... same parameters as PersistentTextField
  // ... plus FormField parameters
  String? Function(String?)? validator,
  void Function(String?)? onSaved,
  AutovalidateMode? autovalidateMode,
})
```

### PersistentTextController

TextEditingController with automatic persistence.

#### Constructor

```dart
PersistentTextController({
  required String storageKey,
  PersistentStateManager? stateManager,
  String defaultValue = '',
  Duration debounce = const Duration(milliseconds: 500),
  String? Function(String)? validator,
  void Function(String)? onChanged,
  void Function()? onSaved,
  void Function(String?)? onError,
})
```

#### Methods

##### initialize()

```dart
Future<void> initialize()
```

Initializes the controller and loads persisted content.

##### save()

```dart
Future<void> save()
```

Forces immediate persistence of current content.

##### revert()

```dart
Future<void> revert()
```

Reverts to the last saved value.

##### clear()

```dart
Future<void> clear()
```

Clears persisted content and resets to default.

#### Properties

```dart
bool get hasUnsavedChanges
String? get lastError
```

---

## 🛠️ **Utility Classes**

### PersistentTextUtils

Utility functions for text field operations.

#### Static Methods

##### saveAll()

```dart
static Future<void> saveAll(
  Map<String, PersistentTextController> controllers, {
  PersistentStateManager? stateManager,
})
```

Saves multiple text controllers at once.

##### clearAll()

```dart
static Future<void> clearAll(
  List<String> storageKeys, {
  PersistentStateManager? stateManager,
})
```

Clears multiple text fields and their persistent data.

##### addToSearchHistory()

```dart
static Future<void> addToSearchHistory(
  String term, {
  String storageKey = 'search_history',
  int maxHistory = 20,
  PersistentStateManager? stateManager,
})
```

Adds a search term to persistent search history.

##### getSearchHistory()

```dart
static Future<List<String>> getSearchHistory({
  String storageKey = 'search_history',
  PersistentStateManager? stateManager,
})
```

Gets persistent search history.

##### clearSearchHistory()

```dart
static Future<void> clearSearchHistory({
  String storageKey = 'search_history',
  PersistentStateManager? stateManager,
})
```

Clears persistent search history.

---

## 🎯 **Convenience Functions**

### persistentField<T>()

```dart
PersistentFieldConfig<T> persistentField<T>(
  String storageKey, {
  required T defaultValue,
})
```

Convenience function to create a persistent field configuration.

**Example:**
```dart
@override
Map<String, PersistentFieldConfig> get persistentFields => {
  'userName': persistentField('user_name', defaultValue: ''),
  'count': persistentField('counter', defaultValue: 0),
  'isEnabled': persistentField('enabled', defaultValue: false),
};
```

---

## ⚠️ **Exceptions**

### PersistenceException

Exception thrown by persistence operations.

#### Constructor

```dart
const PersistenceException({
  required String operation,
  String? key,
  required String message,
  Object? cause,
  StackTrace? stackTrace,
})
```

#### Properties

```dart
String operation    // The operation that failed
String? key        // The key involved, if applicable
String message     // Human-readable error message
Object? cause      // Underlying exception
StackTrace? stackTrace // Stack trace from underlying exception
```

---

## 📊 **Type Definitions**

### PersistentRouteBuilder

```dart
typedef PersistentRouteBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic>? persistentData,
);
```

Builder function for creating routes with automatic persistence.

---

## 🎯 **Usage Examples**

### Basic Widget Setup

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget>
    with PersistentStateMixin<MyWidget> {

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'data': persistentField('my_data', defaultValue: 'default'),
  };

  @override
  void initState() {
    super.initState();
    initializePersistence();
  }

  @override
  void dispose() {
    disposePersistence();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isHydrated) return CircularProgressIndicator();
    
    return Text(getPersistentValue<String>('data'));
  }
}
```

### Custom Backend

```dart
class CustomBackend implements PersistenceBackend {
  @override
  Future<void> setString(String key, String value) async {
    // Your custom storage logic
  }
  
  // ... implement other methods
}

final manager = PersistentStateManager.getNamedInstance(
  'custom',
  backend: CustomBackend(),
);
```

### Advanced Field Configuration

```dart
@override
Map<String, PersistentFieldConfig> get persistentFields => {
  'email': persistentField('user_email', defaultValue: '')
    .withValidation((email) => email.contains('@'))
    .withDebounce(Duration(seconds: 1))
    .withOnChanged((email) => validateForm()),
    
  'preferences': persistentField('prefs', defaultValue: <String, bool>{})
    .withOnChanged((prefs) => applyPreferences(prefs)),
};
```

### Error Handling

```dart
try {
  await setPersistentValue('field', value);
} on ArgumentError catch (e) {
  // Validation failed
  showErrorDialog('Invalid value: $e');
} on PersistenceException catch (e) {
  // Storage operation failed
  showErrorDialog('Save failed: ${e.message}');
}
```

---

This completes the API reference for Flutter Persistent State. For more examples and advanced usage patterns, see the [Advanced Usage Guide](advanced_usage.md).