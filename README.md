# Flutter Persistent State

A comprehensive Flutter package that eliminates boilerplate for app-global persistent state management. Get automatic hydration, reactive updates, and seamless integration with navigation and text fields.

## Why This Package?

Building Flutter apps with persistent state is frustrating. You need:
- Boilerplate code for every piece of data you want to persist
- Manual hydration and saving logic
- Complex state management for reactive updates
- Custom solutions for navigation state and text field persistence

This package solves all of that with a simple annotation-based approach.

## Features

✅ **Zero Boilerplate**: Just add `@PersistentField()` to any field
✅ **Automatic Hydration**: Values load automatically on app start  
✅ **Reactive Updates**: Changes propagate instantly across your app
✅ **Type Safe**: Full null safety and type checking
✅ **Multiple Backends**: SharedPreferences, custom backends, encryption support
✅ **Navigation Integration**: Automatic navigation state persistence
✅ **Text Field Integration**: Smart text field components with auto-save
✅ **Performance Optimized**: Batching, debouncing, and efficient caching
✅ **Production Ready**: Comprehensive error handling and testing

## Quick Start

### 1. Add the dependency

```yaml
dependencies:
  flutter_persistent_state: ^1.0.0
  
dev_dependencies:
  build_runner: ^2.4.7
```

### 2. Annotate your widget

```dart
import 'package:flutter_persistent_state/flutter_persistent_state.dart';

@PersistentState()
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);
  
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> 
    with PersistentStateMixin<UserProfilePage> {
  
  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'userName': persistentField('user_name', defaultValue: ''),
    'userAge': persistentField('user_age', defaultValue: 18),
    'isDarkMode': persistentField('dark_mode', defaultValue: false),
    'preferences': persistentField('user_prefs', defaultValue: <String, dynamic>{}),
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
    if (!isHydrated) {
      return const CircularProgressIndicator();
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Hello ${getPersistentValue<String>('userName')}')),
      body: Column(
        children: [
          // Your values are automatically persisted and reactive
          Switch(
            value: getPersistentValue<bool>('isDarkMode'),
            onChanged: (value) => setPersistentValue('isDarkMode', value),
          ),
          Slider(
            value: getPersistentValue<int>('userAge').toDouble(),
            min: 13,
            max: 120,
            onChanged: (value) => setPersistentValue('userAge', value.round()),
          ),
        ],
      ),
    );
  }
}
```

### 3. Run code generation

```bash
flutter packages pub run build_runner build
```

That's it! Your state is now automatically persisted and hydrated.

## Advanced Features

### Validation and Debouncing

```dart
@override
Map<String, PersistentFieldConfig> get persistentFields => {
  'email': persistentField('user_email', defaultValue: '')
    .withValidation((value) => value.contains('@'))
    .withDebounce(Duration(seconds: 1))
    .withOnChanged((value) => print('Email changed: $value')),
};
```

### Persistent Text Fields

```dart
PersistentTextField(
  storageKey: 'user_name',
  decoration: InputDecoration(labelText: 'Name'),
  validator: (value) => value.length < 2 ? 'Too short' : null,
  debounce: Duration(milliseconds: 500),
  showSaveIndicator: true,
)
```

### Navigation Integration

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _observer = PersistentNavigationObserver();
  
  @override
  Widget build(BuildContext context) {
    return PersistentNavigationWrapper(
      observer: _observer,
      child: MaterialApp(
        navigatorObservers: [_observer],
        home: HomePage(),
      ),
    );
  }
}
```

### Custom Backends

```dart
// Use a custom backend
final customManager = PersistentStateManager.getNamedInstance(
  'secure',
  backend: EncryptedBackend(encryptionKey: 'your-key'),
);

class _MyWidgetState extends State<MyWidget> 
    with PersistentStateMixin<MyWidget> {
  
  @override
  PersistentStateManager get stateManager => customManager;
  
  // Rest of your implementation...
}
```

## Architecture

This package uses a clean, modular architecture:

- **Annotations**: Define what should be persistent
- **Code Generation**: Eliminates boilerplate automatically
- **State Manager**: Coordinates persistence and reactive updates
- **Backends**: Pluggable storage implementations
- **Mixins**: Easy integration with existing widgets
- **Utilities**: Helper components for common use cases

## Performance

- **Batched Operations**: Multiple changes are persisted together
- **Debouncing**: Rapid changes don't overwhelm storage
- **Intelligent Caching**: In-memory cache reduces storage reads
- **Type-Specific Serialization**: Efficient serialization for each data type
- **Background Processing**: Non-blocking persistence operations

## Testing

The package includes comprehensive testing utilities:

```dart
testWidgets('should persist user preferences', (tester) async {
  final backend = MemoryBackend();
  final manager = PersistentStateManager.getNamedInstance('test', backend: backend);
  
  await tester.pumpWidget(MyTestWidget(stateManager: manager));
  
  // Test your persistent state logic
  expect(await manager.getValue<bool>('dark_mode'), isFalse);
  
  await manager.dispose();
});
```

## Migration Guide

### From SharedPreferences

```dart
// Before
final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_name', userName);
final savedName = prefs.getString('user_name') ?? '';

// After
@PersistentField(key: 'user_name', defaultValue: '')
String userName = '';

// Automatically persisted and hydrated!
```

### From Provider/Riverpod

```dart
// Before
class UserProvider extends ChangeNotifier {
  String _name = '';
  String get name => _name;
  
  void setName(String name) {
    _name = name;
    notifyListeners();
    _saveToStorage(name); // Manual persistence
  }
}

// After
@PersistentState()
class UserWidget extends StatefulWidget {
  // Automatic persistence, no boilerplate!
}
```

## API Reference

### Core Classes

- **`PersistentState`**: Annotation for marking widgets with persistent fields
- **`PersistentField`**: Annotation for marking individual fields as persistent
- **`PersistentStateMixin`**: Mixin that provides persistence capabilities
- **`PersistentStateManager`**: Core state management and coordination
- **`PersistenceBackend`**: Interface for storage backends

### Utilities

- **`PersistentTextField`**: Text field with automatic persistence
- **`PersistentNavigationObserver`**: Navigation state persistence
- **`PersistentTextUtils`**: Helper utilities for text field operations

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This package is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Support

- 📖 [Documentation](https://samuelkchris.github.io/flutter_persistent_state/)
- 🐛 [Issue Tracker](https://github.com/samuelkchris/flutter_persistent_state/issues)
- 💬 [Discussions](https://github.com/samuelkchris/flutter_persistent_state/discussions)

---

Made with ❤️ by the Flutter community