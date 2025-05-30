# Flutter Persistent State 🚀

[![pub package](https://img.shields.io/pub/v/flutter_persistent_state.svg)](https://pub.dev/packages/flutter_persistent_state)
[![CI](https://github.com/samuelkchris/flutter_persistent_state/workflows/CI/badge.svg)](https://github.com/samuelkchris/flutter_persistent_state/actions)
[![codecov](https://codecov.io/gh/samuelkchris/flutter_persistent_state/branch/main/graph/badge.svg)](https://codecov.io/gh/samuelkchris/flutter_persistent_state)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Eliminate boilerplate for app-global persistent state management in Flutter.**

Stop wrestling with SharedPreferences boilerplate, manual state hydration, and complex reactive updates. This package provides automatic state persistence with zero configuration, type safety, and reactive updates across your entire app.

## 🎯 **Why This Package?**

Building Flutter apps with persistent state is painful:

```dart
// 😫 The old way - Painful boilerplate everywhere
final prefs = await SharedPreferences.getInstance();
String userName = prefs.getString('user_name') ?? '';

class _MyWidgetState extends State<MyWidget> {
  String _userName = '';
  
  @override
  void initState() {
    super.initState();
    _loadUserName(); // Manual hydration
  }
  
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
    });
  }
  
  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() {
      _userName = name;
    });
    // Manual updates across app... 😵‍💫
  }
}
```

```dart
// ✨ The new way - Pure magic
class _MyWidgetState extends State<MyWidget> 
    with PersistentStateMixin<MyWidget> {
  
  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'userName': persistentField('user_name', defaultValue: ''),
  };
  
  @override
  void initState() {
    super.initState();
    initializePersistence(); // That's it! 🎉
  }
  
  // Automatic hydration ✅
  // Automatic persistence ✅  
  // Reactive updates ✅
  // Type safety ✅
  String get userName => getPersistentValue<String>('userName');
  set userName(String value) => setPersistentValue('userName', value);
}
```

## ✨ **Features**

### **🚀 Core Features**
- **Zero Boilerplate** - Just add a mixin and define your fields
- **Automatic Hydration** - Values load from storage on app start
- **Reactive Updates** - Changes propagate instantly across your app
- **Type Safety** - Full null safety and compile-time type checking
- **Performance Optimized** - Batching, debouncing, and intelligent caching

### **🎛️ Advanced Features**
- **Multiple Backends** - SharedPreferences, encrypted storage, custom backends
- **Navigation Integration** - Automatic navigation state persistence
- **Smart Text Fields** - Text fields with auto-save and validation
- **Code Generation** - Optional annotation-based approach for even less boilerplate
- **Testing Support** - Mock backends and comprehensive test utilities

### **🏗️ Production Ready**
- **Error Handling** - Graceful degradation and recovery
- **Validation** - Built-in and custom validation support
- **Migration Support** - Data migration utilities for app updates
- **Performance Monitoring** - Built-in performance metrics
- **Memory Efficient** - Intelligent caching and cleanup

## 📦 **Installation**

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_persistent_state: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.7  # Optional: for code generation
```

Then run:
```bash
flutter pub get
```

## 🚀 **Quick Start**

### **1. Basic Usage (Manual Approach)**

```dart
import 'package:flutter_persistent_state/flutter_persistent_state.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});
  
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> 
    with PersistentStateMixin<UserProfilePage> {
  
  // Define your persistent fields
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
    initializePersistence(); // Initialize persistence
  }
  
  @override
  void dispose() {
    disposePersistence(); // Clean up
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Show loading while hydrating
    if (!isHydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello ${getPersistentValue<String>('userName')}!'),
      ),
      body: Column(
        children: [
          // Values are automatically persisted and reactive!
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

**That's it!** Your state is now automatically persisted and hydrated. No SharedPreferences boilerplate, no manual state management.

### **2. Advanced Usage with Validation & Debouncing**

```dart
@override
Map<String, PersistentFieldConfig> get persistentFields => {
  'email': persistentField('user_email', defaultValue: '')
    .withValidation((value) => value.contains('@'))
    .withDebounce(const Duration(seconds: 1))
    .withOnChanged((value) => print('Email changed: $value')),
    
  'password': persistentField('user_password', defaultValue: '')
    .withValidation((value) => value.length >= 8)
    .withOnChanged((value) => _validateForm()),
};
```

### **3. Persistent Text Fields**

```dart
import 'package:flutter_persistent_state/flutter_persistent_state.dart';

PersistentTextField(
  storageKey: 'user_name',
  decoration: const InputDecoration(labelText: 'Name'),
  validator: (value) => value.length < 2 ? 'Too short' : null,
  debounce: const Duration(milliseconds: 500),
  showSaveIndicator: true,
  onSaved: () => print('Name saved!'),
)
```

### **4. Navigation State Persistence**

```dart
void main() {
  final observer = PersistentNavigationObserver();
  
  runApp(
    PersistentNavigationWrapper(
      observer: observer,
      child: MaterialApp(
        navigatorObservers: [observer],
        // Your app continues here...
      ),
    ),
  );
}
```

Now your users will return to exactly where they left off! 🎯

## 🎨 **Code Generation (Optional)**

For even less boilerplate, use the annotation approach:

### **1. Define Your Widget with Annotations**

```dart
import 'package:flutter_persistent_state/flutter_persistent_state.dart';

part 'user_profile.persistent.dart';  // Generated file

@PersistentState()
class UserProfilePage extends StatefulWidget {
  @PersistentField(key: 'user_name', defaultValue: '')
  final String userName;
  
  @PersistentField(key: 'user_age', defaultValue: 18)
  final int userAge;
  
  @PersistentField(key: 'dark_mode', defaultValue: false)
  final bool isDarkMode;
  
  const UserProfilePage({super.key});
  
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}
```

### **2. Generate Code**

```bash
dart run build_runner build
```

### **3. Use Type-Safe Generated Code**

```dart
class _UserProfilePageState extends State<UserProfilePage>
    with PersistentStateMixin<UserProfilePage> {
  // No need to define persistentFields - it's generated!
  
  @override
  void initState() {
    super.initState();
    initializePersistence();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Hello $userName!'),  // Generated getter
          Switch(
            value: isDarkMode,       // Generated getter
            onChanged: setIsDarkMode, // Generated setter
          ),
        ],
      ),
    );
  }
}
```

## 🔧 **Custom Backends**

### **Encrypted Storage**

```dart
import 'package:flutter_persistent_state/backends/encrypted_backend.dart';

final secureManager = PersistentStateManager.getNamedInstance(
  'secure',
  backend: EncryptedBackend(encryptionKey: 'your-secret-key'),
);

class _SecureWidgetState extends State<SecureWidget> 
    with PersistentStateMixin<SecureWidget> {
  
  @override
  PersistentStateManager get stateManager => secureManager;
  
  // Your sensitive data is now encrypted!
}
```

### **Custom Backend**

```dart
class FirebaseBackend implements PersistenceBackend {
  // Implement your custom storage logic
  @override
  Future<void> setString(String key, String value) async {
    await FirebaseFirestore.instance
        .collection('user_data')
        .doc(key)
        .set({'value': value});
  }
  
  // ... implement other methods
}

final firebaseManager = PersistentStateManager.getNamedInstance(
  'firebase',
  backend: FirebaseBackend(),
);
```

## 📱 **Real-World Examples**

### **User Onboarding Flow**

```dart
class OnboardingScreen extends StatefulWidget with PersistentStateMixin {
  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'currentPage': persistentField('onboarding_page', defaultValue: 0),
    'userName': persistentField('onboarding_name', defaultValue: ''),
    'hasSeenIntro': persistentField('has_seen_intro', defaultValue: false),
  };
  
  void nextPage() {
    final current = getPersistentValue<int>('currentPage');
    setPersistentValue('currentPage', current + 1);
    // Page state automatically persisted!
  }
}
```

### **Shopping Cart**

```dart
class ShoppingCart extends StatefulWidget with PersistentStateMixin {
  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'cartItems': persistentField('cart_items', defaultValue: <Map<String, dynamic>>[]),
    'totalPrice': persistentField('total_price', defaultValue: 0.0),
    'selectedShipping': persistentField('shipping_method', defaultValue: 'standard'),
  };
  
  void addItem(Map<String, dynamic> item) {
    final items = List<Map<String, dynamic>>.from(
      getPersistentValue<List<Map<String, dynamic>>>('cartItems')
    );
    items.add(item);
    setPersistentValue('cartItems', items);
    // Cart persists across app sessions!
  }
}
```

### **User Preferences**

```dart
class SettingsScreen extends StatefulWidget with PersistentStateMixin {
  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'theme': persistentField('app_theme', defaultValue: 'system'),
    'notifications': persistentField('notifications_enabled', defaultValue: true),
    'language': persistentField('app_language', defaultValue: 'en'),
    'fontSize': persistentField('font_size', defaultValue: 16.0)
      .withValidation((value) => value >= 12.0 && value <= 24.0),
  };
}
```

## 🎯 **Performance Benefits**

- **Batched Writes** - Multiple changes written together for efficiency
- **Intelligent Caching** - Reduced storage reads with smart cache management
- **Debounced Updates** - Prevents excessive writes from rapid changes
- **Type-Specific Storage** - Optimized serialization for each data type
- **Memory Efficient** - Automatic cleanup and resource management

## 🧪 **Testing**

The package includes comprehensive testing utilities:

```dart
import 'package:flutter_persistent_state/testing.dart';

testWidgets('should persist user preferences', (tester) async {
  final backend = MemoryBackend();
  final manager = PersistentStateManager.getNamedInstance('test', backend: backend);
  
  await tester.pumpWidget(MyTestWidget(stateManager: manager));
  
  // Test your persistent state logic
  expect(await manager.getValue<bool>('dark_mode'), isFalse);
  
  // Simulate user interaction
  await tester.tap(find.byType(Switch));
  await tester.pump();
  
  expect(await manager.getValue<bool>('dark_mode'), isTrue);
  
  await manager.dispose();
});
```

## 🚀 **Migration from Other Solutions**

### **From SharedPreferences**

```dart
// Before
final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_name', userName);
final savedName = prefs.getString('user_name') ?? '';

// After  
await setPersistentValue('userName', userName);
final savedName = getPersistentValue<String>('userName');
```

### **From Provider**

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
@override
Map<String, PersistentFieldConfig> get persistentFields => {
  'userName': persistentField('user_name', defaultValue: ''),
};

// Automatic persistence, no manual work needed!
```

### **From Riverpod**

```dart
// Before
final userNameProvider = StateNotifierProvider<UserNameNotifier, String>((ref) {
  return UserNameNotifier();
});

class UserNameNotifier extends StateNotifier<String> {
  UserNameNotifier() : super('') {
    _loadFromStorage(); // Manual loading
  }
  
  void setName(String name) {
    state = name;
    _saveToStorage(name); // Manual saving
  }
}

// After - much simpler!
'userName': persistentField('user_name', defaultValue: ''),
```

## 📚 **Documentation**

- 📖 [Getting Started Guide](doc/getting_started.md) - Step-by-step tutorial
- 🎯 [Advanced Usage](doc/advanced_usage.md) - Complex scenarios and patterns
- 📋 [API Reference](doc/api_reference.md) - Complete API documentation
- 🔧 [Custom Backends](doc/custom_backends.md) - Creating your own storage backend

## 🤝 **Contributing**

We welcome contributions! Here's how you can help:

1. **Report Issues** - Found a bug? [Open an issue](https://github.com/samuelkchris/flutter_persistent_state/issues)
2. **Request Features** - Have an idea? [Start a discussion](https://github.com/samuelkchris/flutter_persistent_state/discussions)
3. **Submit PRs** - Want to contribute code? See our [contributing guide](CONTRIBUTING.md)
4. **Improve Docs** - Documentation improvements are always welcome!

### **Development Setup**

```bash
git clone https://github.com/samuelkchris/flutter_persistent_state.git
cd flutter_persistent_state
flutter pub get
dart run build_runner build
flutter test
```

## 📊 **Changelog**

See [CHANGELOG.md](CHANGELOG.md) for a complete list of changes.

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- Flutter team for the amazing framework
- SharedPreferences plugin maintainers
- All contributors and users of this package

## 📞 **Support**

- 📖 [Documentation](https://samuelkchris.github.io/flutter_persistent_state/)
- 🐛 [Issue Tracker](https://github.com/samuelkchris/flutter_persistent_state/issues)
- 💬 [Discussions](https://github.com/samuelkchris/flutter_persistent_state/discussions)
- 📧 [Email Support](mailto:support@samuelkchris.com)

---

**Made with ❤️ by the Flutter community**

**⭐ If this package helped you, please give it a star on GitHub!**