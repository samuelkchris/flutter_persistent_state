/// Flutter Persistent State - Eliminate boilerplate for app-global persistent state management.
///
/// This library provides automatic state persistence and hydration for Flutter applications
/// through a simple annotation-based approach. It eliminates the need for manual state
/// management boilerplate while providing reactive updates, type safety, and excellent
/// performance.
///
/// ## Quick Start
///
/// 1. Add the dependency to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   flutter_persistent_state: ^1.0.0
/// ```
///
/// 2. Annotate your StatefulWidget:
/// ```dart
/// @PersistentState()
/// class MyWidget extends StatefulWidget {
///   // Your widget implementation
/// }
/// ```
///
/// 3. Use the PersistentStateMixin in your State class:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with PersistentStateMixin<MyWidget> {
///   @override
///   Map<String, PersistentFieldConfig> get persistentFields => {
///     'userName': persistentField('user_name', defaultValue: ''),
///     'counter': persistentField('counter', defaultValue: 0),
///   };
///
///   @override
///   void initState() {
///     super.initState();
///     initializePersistence();
///   }
///
///   @override
///   void dispose() {
///     disposePersistence();
///     super.dispose();
///   }
/// }
/// ```
///
/// ## Core Features
///
/// - **Zero Boilerplate**: Automatic persistence with simple annotations
/// - **Type Safe**: Full null safety and compile-time type checking
/// - **Reactive**: Automatic UI updates when persisted values change
/// - **Performance Optimized**: Batching, debouncing, and intelligent caching
/// - **Multiple Backends**: SharedPreferences, custom backends, encryption support
/// - **Navigation Integration**: Automatic navigation state persistence
/// - **Text Field Integration**: Smart text field components with auto-save
/// - **Validation Support**: Built-in validation with custom validators
/// - **Testing Utilities**: Comprehensive testing support with mock backends
///
/// ## Advanced Usage
///
/// ### Custom Validation and Debouncing
/// ```dart
/// 'email': persistentField('user_email', defaultValue: '')
///   .withValidation((value) => value.contains('@'))
///   .withDebounce(Duration(seconds: 1))
///   .withOnChanged((value) => print('Email: $value')),
/// ```
///
/// ### Persistent Text Fields
/// ```dart
/// PersistentTextField(
///   storageKey: 'user_name',
///   decoration: InputDecoration(labelText: 'Name'),
///   validator: (value) => value.length < 2 ? 'Too short' : null,
///   showSaveIndicator: true,
/// )
/// ```
///
/// ### Navigation State Persistence
/// ```dart
/// MaterialApp(
///   navigatorObservers: [PersistentNavigationObserver()],
///   // Your app configuration
/// )
/// ```
///
/// ### Custom Backends
/// ```dart
/// final customManager = PersistentStateManager.getNamedInstance(
///   'secure',
///   backend: EncryptedBackend(encryptionKey: 'your-key'),
/// );
/// ```
///
/// ## Architecture
///
/// The library is built with a clean, modular architecture:
///
/// - **Annotations**: Define what should be persistent with `@PersistentState` and `@PersistentField`
/// - **Code Generation**: Eliminates boilerplate automatically using build_runner
/// - **State Manager**: Coordinates persistence, caching, and reactive updates
/// - **Backends**: Pluggable storage implementations (SharedPreferences, custom, encrypted)
/// - **Mixins**: Easy integration with existing StatefulWidget classes
/// - **Utilities**: Helper components for text fields, navigation, and common operations
///
/// The system is designed to be non-intrusive and work seamlessly with existing Flutter
/// applications while providing powerful persistence capabilities with minimal setup.
library flutter_persistent_state;

export 'annotations/persistent_annotations.dart';
export 'backends/persistence_backend.dart';
export 'backends/shared_preferences_backend.dart';
export 'core/persistent_state_manager.dart';
export 'core/persistent_state_mixin.dart';
export 'navigation/navigation_integration.dart';
export 'widgets/text_field_integration.dart';
export 'utils/persistent_text_utils.dart';
