# Getting Started with Flutter Persistent State

This guide will walk you through setting up and using the Flutter Persistent State package in your app. By the end, you'll have automatic state persistence working with zero boilerplate.

## 📋 **Prerequisites**

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Basic understanding of StatefulWidget and State management

## 🚀 **Step 1: Installation**

### Add the Package

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_persistent_state: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.7  # Optional: for code generation
```

### Install Dependencies

```bash
flutter pub get
```

## 🎯 **Step 2: Your First Persistent Widget**

Let's create a simple counter app that remembers its value across app restarts.

### Create the Widget

```dart
// lib/counter_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_persistent_state/flutter_persistent_state.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage>
    with PersistentStateMixin<CounterPage> {
  
  // Step 1: Define your persistent fields
  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'counter': persistentField('counter_value', defaultValue: 0),
  };

  @override
  void initState() {
    super.initState();
    // Step 2: Initialize persistence
    initializePersistence();
  }

  @override
  void dispose() {
    // Step 3: Clean up resources
    disposePersistence();
    super.dispose();
  }

  void _incrementCounter() {
    final currentValue = getPersistentValue<int>('counter');
    setPersistentValue('counter', currentValue + 1);
    // That's it! Value is automatically persisted
  }

  @override
  Widget build(BuildContext context) {
    // Step 4: Show loading while hydrating
    if (!isHydrated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Persistent Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${getPersistentValue<int>('counter')}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Test It Out

1. **Run your app**: `flutter run`
2. **Increment the counter** a few times
3. **Hot restart** the app (or close and reopen)
4. **See the magic** ✨ - Your counter value is preserved!

## 🎨 **Step 3: Multiple Field Types**

Let's expand our example to handle different types of data:

```dart
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with PersistentStateMixin<UserProfilePage> {

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    // String field
    'userName': persistentField('user_name', defaultValue: 'Anonymous'),
    
    // Integer field
    'userAge': persistentField('user_age', defaultValue: 25),
    
    // Boolean field
    'isDarkMode': persistentField('dark_mode', defaultValue: false),
    
    // List field
    'favoriteColors': persistentField('favorite_colors', 
        defaultValue: <String>['blue', 'green']),
    
    // Map field
    'settings': persistentField('user_settings', 
        defaultValue: <String, dynamic>{
          'notifications': true,
          'sound': false,
        }),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${getPersistentValue<String>('userName')}!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // String field
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              controller: TextEditingController(
                text: getPersistentValue<String>('userName'),
              ),
              onChanged: (value) => setPersistentValue('userName', value),
            ),
            
            const SizedBox(height: 16),
            
            // Integer field with slider
            Text('Age: ${getPersistentValue<int>('userAge')}'),
            Slider(
              value: getPersistentValue<int>('userAge').toDouble(),
              min: 18,
              max: 80,
              onChanged: (value) => setPersistentValue('userAge', value.round()),
            ),
            
            const SizedBox(height: 16),
            
            // Boolean field with switch
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: getPersistentValue<bool>('isDarkMode'),
              onChanged: (value) => setPersistentValue('isDarkMode', value),
            ),
            
            const SizedBox(height: 16),
            
            // List field display
            Text('Favorite Colors: ${getPersistentValue<List<String>>('favoriteColors').join(', ')}'),
            
            const SizedBox(height: 16),
            
            // Map field display
            Text('Settings: ${getPersistentValue<Map<String, dynamic>>('settings')}'),
          ],
        ),
      ),
    );
  }
}
```

## 🔧 **Step 4: Adding Validation**

Add validation to ensure data integrity:

```dart
@override
Map<String, PersistentFieldConfig> get persistentFields => {
  'email': persistentField('user_email', defaultValue: '')
    .withValidation((value) {
      // Validate email format
      return value.contains('@') && value.contains('.');
    }),
    
  'age': persistentField('user_age', defaultValue: 18)
    .withValidation((value) {
      // Validate age range
      return value >= 13 && value <= 120;
    }),
    
  'password': persistentField('password', defaultValue: '')
    .withValidation((value) {
      // Validate password strength
      return value.length >= 8 && value.contains(RegExp(r'[0-9]'));
    }),
};

// Usage with error handling
void _updateEmail(String email) async {
  try {
    await setPersistentValue('email', email);
    // Success - email was valid and saved
  } catch (e) {
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid email: $e')),
    );
  }
}
```

## ⏱️ **Step 5: Adding Debouncing**

Prevent excessive saves with debouncing:

```dart
@override
Map<String, PersistentFieldConfig> get persistentFields => {
  'searchQuery': persistentField('search_query', defaultValue: '')
    .withDebounce(const Duration(milliseconds: 500)),
    
  'chatMessage': persistentField('draft_message', defaultValue: '')
    .withDebounce(const Duration(seconds: 2)),
};

// Now rapid typing won't spam the storage system
TextField(
  onChanged: (value) => setPersistentValue('searchQuery', value),
  // Saves will be debounced automatically
)
```

## 📱 **Step 6: Adding Change Callbacks**

React to value changes:

```dart
@override
Map<String, PersistentFieldConfig> get persistentFields => {
  'theme': persistentField('app_theme', defaultValue: 'light')
    .withOnChanged((value) {
      print('Theme changed to: $value');
      // Update app theme
      _updateAppTheme(value);
    }),
    
  'language': persistentField('app_language', defaultValue: 'en')
    .withOnChanged((value) {
      print('Language changed to: $value');
      // Restart app with new locale
      _updateLocale(value);
    }),
};
```

## 🧪 **Step 7: Testing Your Persistent State**

Create tests to ensure your persistent state works correctly:

```dart
// test/counter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_persistent_state/flutter_persistent_state.dart';
import 'package:flutter_persistent_state/testing.dart';

import '../lib/counter_page.dart';

void main() {
  group('Counter Page Tests', () {
    testWidgets('should persist counter value', (tester) async {
      // Create a test backend
      final backend = MemoryBackend();
      final manager = PersistentStateManager.getNamedInstance(
        'test',
        backend: backend,
      );

      // Create widget with test manager
      await tester.pumpWidget(
        MaterialApp(
          home: CounterPage(),
        ),
      );

      // Wait for hydration
      await tester.pumpAndSettle();

      // Initial counter should be 0
      expect(find.text('0'), findsOneWidget);

      // Tap increment button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Counter should be 1
      expect(find.text('1'), findsOneWidget);

      // Verify value was persisted
      final persistedValue = await manager.getValue<int>('counter_value');
      expect(persistedValue, equals(1));

      await manager.dispose();
    });
  });
}
```

## 🚀 **Step 8: Advanced Features**

### Reactive Streams

Listen to value changes across your app:

```dart
class ReactiveWidget extends StatefulWidget {
  @override
  State<ReactiveWidget> createState() => _ReactiveWidgetState();
}

class _ReactiveWidgetState extends State<ReactiveWidget>
    with PersistentStateMixin<ReactiveWidget> {

  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'sharedCounter': persistentField('shared_counter', defaultValue: 0),
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: getPersistentValueStream<int>('sharedCounter'),
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0;
        return Text('Shared Counter: $value');
        // This widget updates automatically when the value changes
        // from ANY other widget in your app!
      },
    );
  }
}
```

### Reset Functions

Reset fields to their defaults:

```dart
// Reset a single field
await resetPersistentField('counter');

// Reset all fields
await resetAllPersistentFields();

// Custom reset with confirmation
void _resetUserData() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset Data'),
      content: const Text('Are you sure you want to reset all data?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Reset'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await resetAllPersistentFields();
  }
}
```

## 🎯 **Common Patterns**

### User Onboarding

```dart
class OnboardingFlow extends StatefulWidget with PersistentStateMixin {
  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'currentStep': persistentField('onboarding_step', defaultValue: 0),
    'userName': persistentField('onboarding_name', defaultValue: ''),
    'hasCompletedIntro': persistentField('completed_intro', defaultValue: false),
  };

  void nextStep() {
    final current = getPersistentValue<int>('currentStep');
    setPersistentValue('currentStep', current + 1);
  }

  void completeOnboarding() {
    setPersistentValue('hasCompletedIntro', true);
    // Navigate to main app
  }
}
```

### Shopping Cart

```dart
class ShoppingCart extends StatefulWidget with PersistentStateMixin {
  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'cartItems': persistentField('cart_items', defaultValue: <Map<String, dynamic>>[]),
    'totalPrice': persistentField('total_price', defaultValue: 0.0),
  };

  void addToCart(Map<String, dynamic> item) {
    final items = List<Map<String, dynamic>>.from(
      getPersistentValue<List<Map<String, dynamic>>>('cartItems')
    );
    items.add(item);
    setPersistentValue('cartItems', items);
    
    // Update total
    final total = items.fold<double>(0.0, (sum, item) => sum + item['price']);
    setPersistentValue('totalPrice', total);
  }
}
```

### User Preferences

```dart
class AppSettings extends StatefulWidget with PersistentStateMixin {
  @override
  Map<String, PersistentFieldConfig> get persistentFields => {
    'theme': persistentField('app_theme', defaultValue: 'system')
      .withOnChanged(_updateTheme),
    'language': persistentField('app_language', defaultValue: 'en')
      .withOnChanged(_updateLanguage),
    'notifications': persistentField('notifications_enabled', defaultValue: true),
  };

  void _updateTheme(String theme) {
    // Apply theme changes
    MyApp.of(context).updateTheme(theme);
  }

  void _updateLanguage(String language) {
    // Apply language changes
    MyApp.of(context).updateLocale(language);
  }
}
```

## 🎉 **Next Steps**

Congratulations! You now know the basics of Flutter Persistent State. Here's what to explore next:

1. **[Advanced Usage Guide](advanced_usage.md)** - Learn about custom backends, encryption, and performance optimization
2. **[API Reference](api_reference.md)** - Complete API documentation
3. **[Testing Guide](testing.md)** - Comprehensive testing strategies
4. **[Navigation Integration](navigation_integration.md)** - Automatic navigation state persistence

## 🤔 **Need Help?**

- 🐛 [Report Issues](https://github.com/samuelkchris/flutter_persistent_state/issues)
- 💬 [Ask Questions](https://github.com/samuelkchris/flutter_persistent_state/discussions)
- 📚 [Read Documentation](https://samuelkchris.github.io/flutter_persistent_state/)

Happy coding! 🚀